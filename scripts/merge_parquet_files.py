"""
Given a directory, merge all parquet files inside the directory
on the assumption that they have the same schema.

Parquet files are originally written with awkward.to_parquet(ret_record, ofn),
where ret_record is an ak.Record whose fields are arrays. Each such file is
therefore a single parquet row. Merging concatenates each field across files,
so a field with N0 entries in file0, N1 in file1, ... ends up with
N0 + N1 + ... entries in the output.
"""
import argparse
import os
import awkward as ak


def main():
    args = options()
    merge_parquet_files(args.directory, args.output_file)


def options():
    parser = argparse.ArgumentParser(description="Merge all parquet files in a directory into a single parquet file")
    parser.add_argument("directory", help="Directory containing parquet files")
    parser.add_argument("output_file", help="Output parquet file")
    return parser.parse_args()


def merge_parquet_files(directory, output_file):
    print("Listing parquet files ...")
    parquet_files = sorted(
        os.path.join(directory, f) for f in os.listdir(directory) if f.endswith(".parquet")
    )
    if not parquet_files:
        raise ValueError("No parquet files found in the directory")

    print(f"Reading {len(parquet_files)} parquet files ...")
    arrays = [ak.from_parquet(f) for f in parquet_files]

    print("Concatenating ...")
    if all(isinstance(a, ak.Record) for a in arrays):
        # Each file holds one ak.Record: concatenate field by field
        records = arrays
        fields = records[0].fields
        for fname, rec in zip(parquet_files, records):
            if rec.fields != fields:
                raise ValueError(f"Field mismatch in {fname}: {rec.fields} != {fields}")
        merged = ak.Record({field: ak.concatenate([rec[field] for rec in records]) for field in fields})
        for field in fields:
            print(f"  {field}: {len(merged[field])} entries")
    else:
        # Files are plain arrays with many rows: concatenate along rows
        merged = ak.concatenate(arrays)
        print(f"  {len(merged)} rows")

    print("Writing ...")
    ak.to_parquet(merged, output_file)


if __name__ == "__main__":
    main()
