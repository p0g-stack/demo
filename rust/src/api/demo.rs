//! What page 3 calls: the same work as the Dart `crunch`, and where this
//! build of the crate is running.
use flutter_rust_bridge::frb;

/// Counts the primes below `n` by trial division, the same algorithm as
/// `DemoService.crunch`, so the two times compare.
#[frb(sync)]
pub fn count_primes(n: u32) -> u32 {
    let mut count = 0;
    for i in 2..n {
        let mut prime = true;
        let mut d = 2;
        while d * d <= i {
            if i % d == 0 {
                prime = false;
                break;
            }
            d += 1;
        }
        if prime {
            count += 1;
        }
    }
    count
}

/// The target this copy of the crate was compiled for, e.g.
/// `wasm32-unknown (single-threaded)` or `x86_64-linux`.
#[frb(sync)]
pub fn build_target() -> String {
    let arch = std::env::consts::ARCH;
    let os = std::env::consts::OS;
    if cfg!(target_arch = "wasm32") {
        let threads = if cfg!(target_feature = "atomics") {
            "threads"
        } else {
            "single-threaded"
        };
        format!("{arch}-unknown ({threads})")
    } else {
        format!("{arch}-{os}")
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn counts_primes() {
        assert_eq!(super::count_primes(100), 25);
        assert_eq!(super::count_primes(2), 0);
    }
}
