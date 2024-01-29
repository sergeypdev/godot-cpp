import sys
from binding_generator import generate_bindings

print("args", sys.argv)

if __name__ == "__main__":
    # api_filepath, use_template_get_node, bits="64", precision="single", output_dir="."
    generate_bindings(
        sys.argv[1],
        False,
        "64",
        "single",
        sys.argv[2],
    )
