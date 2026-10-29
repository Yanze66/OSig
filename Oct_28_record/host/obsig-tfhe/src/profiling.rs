use crate::utility;
use serde::{de::DeserializeOwned, Serialize};
use std::path::Path;
use std::time::Instant;

#[derive(Clone, Default)]
pub struct AlgorithmTiming {
    pub wall_seconds: f64,
    pub worker_seconds: f64,
}

/// Measures actual builder execution separately from cache I/O and lock waits.
#[derive(Clone, Default)]
pub struct CacheTiming {
    pub build_seconds: f64,
    pub loaded: usize,
    pub built: usize,
}

impl CacheTiming {
    pub fn merge(&mut self, other: &Self) {
        self.build_seconds += other.build_seconds;
        self.loaded += other.loaded;
        self.built += other.built;
    }

    pub fn load<T, F>(&mut self, path: &Path, build: F) -> T
    where
        T: Serialize + DeserializeOwned + Clone,
        F: FnOnce() -> T,
    {
        let mut did_build = false;
        let result = utility::load_or_create(path, || {
            did_build = true;
            let start = Instant::now();
            let result = build();
            self.build_seconds += start.elapsed().as_secs_f64();
            result
        });
        if did_build { self.built += 1; } else { self.loaded += 1; }
        result
    }
}

pub fn row(scope: &str, name: &str, wall: Option<f64>, worker: f64, recipients: usize) -> String {
    let wall_text = wall.map(|v| format!("{v:.6}")).unwrap_or_else(|| "N/A".into());
    let per_recipient = if recipients == 0 { 0.0 } else { worker / recipients as f64 };
    println!("{name:<32} {wall_text:>14} {worker:>16.6} {per_recipient:>20.6}");
    format!("ALGORITHM_CSV,{scope},{name},{},{worker:.9},{per_recipient:.9},{recipients}",
        wall.map(|v| format!("{v:.9}")).unwrap_or_default())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cache_profile_distinguishes_build_from_load() {
        let dir = std::env::temp_dir().join(format!("osig-profile-test-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("cache.bin");
        if path.exists() { std::fs::remove_file(&path).unwrap(); }
        let mut cold = CacheTiming::default();
        let value: u64 = cold.load(&path, || 42);
        assert_eq!(value, 42);
        assert_eq!((cold.loaded, cold.built), (0, 1));
        let mut warm = CacheTiming::default();
        let value: u64 = warm.load(&path, || panic!("cache hit must not run builder"));
        assert_eq!(value, 42);
        assert_eq!((warm.loaded, warm.built), (1, 0));
        assert_eq!(warm.build_seconds, 0.0);
        let build_seconds = cold.build_seconds;
        cold.merge(&warm);
        assert_eq!((cold.loaded, cold.built), (1, 1));
        assert_eq!(cold.build_seconds, build_seconds);
        std::fs::remove_file(path).unwrap();
        std::fs::remove_dir(dir).unwrap();
    }
}
