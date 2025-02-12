# Social Network Smart Contract

A Starknet-based smart contract implementing core social media functionalities including posts, comments, and likes.

## Features

- **Post Creation** ([post.cairo](src/post.cairo) L11-19)
  - Create original posts
  - Create comments on existing posts
- **Engagement Features**
  - Like posts (prevent self-likes and duplicate likes)
  - Track likes count per post
- **Data Retrieval**
  - Get post author
  - Check if post is a comment
  - View likes count
- **Security Features**
  - Ownership validation
  - Parent post existence checks
  - Anti-spam measures for likes

## Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) 2.9.2
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) 0.37

## Installation

1. Clone repository:

```bash
git clone https://github.com/your-repo/social-network.git
cd social-network
```

2. Build project:

```bash
scarb build
```

## Testing

Run comprehensive test suite:

```bash
snforge test
```

Test coverage includes:

- Post/comment creation workflows
- Like functionality with edge cases
- Access control validations
- Data integrity checks

## Project Structure

```
├── Scarb.toml          # Project configuration
├── src/
│   ├── lib.cairo       # Module declarations
│   └── post.cairo      # Core social media logic (L1-145)
├── tests/
│   └── test_social.cairo # Integration tests (L1-130)
└── README.md           # This document
```

## License

MIT License - See [LICENSE](LICENSE) for details
