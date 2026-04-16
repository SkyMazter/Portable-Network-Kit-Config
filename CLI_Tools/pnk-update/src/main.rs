use clap::Parser;
#[derive(Parser, Debug)]
#[clap(author, version, about="The tool used to update the pnk and its dependancies.")]

struct Args {
    // #[clap(help="There are no args, just run the command.")]
}

fn main() {
    println!("Hello, world!");
}
