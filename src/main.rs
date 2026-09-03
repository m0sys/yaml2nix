use serde::Deserialize;
use std::io::Read;
use yaml_serde::Value;

fn main() {
    let file_name = &std::env::args().collect::<Vec<_>>()[1];
    let mut file = std::fs::File::open(file_name).expect("could not open file");
    let mut document = String::new();
    file.read_to_string(&mut document).unwrap();

    print!("{}", convert_doc(document))
}

fn convert_doc(document: String) -> String {
    let deserializer = yaml_serde::Deserializer::from_str(&document);

    let docs: yaml_serde::Sequence = deserializer
        .filter_map(|document| {
            match Value::deserialize(document) {
                Ok(doc) => Some(doc),
                Err(e) if format!("{:?}", e) == "EndOfStream" => {
                    // An empty document can result in this; let's assume it's non-fatal
                    None
                }
                Err(e) => {
                    panic!("Unable to deserialize document: {}", e);
                }
            }
        })
        .collect();

    let len = docs.len();
    match len {
        0 => {
            panic!("no document supplied");
        }
        1 => {
            let nix_string = serde_nix::to_string(&docs[0]).unwrap();
            nixpkgs_fmt::reformat_string(&nix_string)
        }
        _ => {
            let nix_string = serde_nix::to_string(&docs).unwrap();
            nixpkgs_fmt::reformat_string(&nix_string)
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_documents() {
        for pairs in [
            (
                include_str!("testdata/deployment.yaml"),
                include_str!("testdata/deployment.nix"),
            ),
            (
                include_str!("testdata/multi-doc.yaml"),
                include_str!("testdata/multi-doc.nix"),
            ),
            (
                include_str!("testdata/escape.yaml"),
                include_str!("testdata/escape.nix"),
            ),
            (
                include_str!("testdata/keywords.yaml"),
                include_str!("testdata/keywords.nix"),
            ),
        ] {
            assert_eq!(pairs.1, convert_doc(pairs.0.to_string()));
        }
    }
}
