use starknet::*;
use starknet::storage::*;

#[derive(Drop, Serde, Copy, starknet::Store)]
pub struct Post {
    id: u256,
    author: ContractAddress,
    parent_post_id: Option<u256>,
    likes_count: u32,
}

#[starknet::interface]
pub trait IPost<TContractState> {
    fn create_post(ref self: TContractState) -> u256;
    fn create_comment(ref self: TContractState, parent_post_id: u256) -> u256;
    fn like_post(ref self: TContractState, post_id: u256);
    fn get_post_author(self: @TContractState, post_id: u256) -> ContractAddress;
    fn get_post_likes(self: @TContractState, post_id: u256) -> u32;
    fn is_comment(self: @TContractState, post_id: u256) -> bool;
}

#[starknet::contract]
pub mod SocialPost {
    use core::num::traits::Zero;
    use starknet::storage::*;
    use starknet::{ContractAddress, get_caller_address};
    use super::Post;

    #[storage]
    struct Storage {
        posts: Map<u256, Post>,
        next_post_id: u256,
        user_likes: Map<(u256, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PostCreated: PostCreated,
        PostLiked: PostLiked,
    }

    #[derive(Drop, starknet::Event)]
    struct PostCreated {
        post_id: u256,
        author: ContractAddress,
        parent_post_id: Option<u256>,
    }

    #[derive(Drop, starknet::Event)]
    struct PostLiked {
        post_id: u256,
        liker: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.next_post_id.write(1);
    }

    #[abi(embed_v0)]
    impl PostImpl of super::IPost<ContractState> {
        fn create_post(ref self: ContractState) -> u256 {
            let post_id = self.next_post_id.read();
            self.next_post_id.write(post_id + 1);

            let post = Post {
                id: post_id,
                author: get_caller_address(),
                parent_post_id: Option::None,
                likes_count: 0,
            };
            self.posts.write(post_id, post);
            self
                .emit(
                    Event::PostCreated(
                        PostCreated {
                            post_id, author: get_caller_address(), parent_post_id: Option::None,
                        },
                    ),
                );
            post_id
        }

        fn create_comment(ref self: ContractState, parent_post_id: u256) -> u256 {
            assert(self.posts.read(parent_post_id).id.is_non_zero(), 'Parent post does not exist');

            let post_id = self.next_post_id.read();
            self.next_post_id.write(post_id + 1);

            let post = Post {
                id: post_id,
                author: get_caller_address(),
                parent_post_id: Option::Some(parent_post_id),
                likes_count: 0,
            };
            self.posts.write(post_id, post);
            self
                .emit(
                    Event::PostCreated(
                        PostCreated {
                            post_id,
                            author: get_caller_address(),
                            parent_post_id: Option::Some(parent_post_id),
                        },
                    ),
                );
            post_id
        }

        fn like_post(ref self: ContractState, post_id: u256) {
            let post = self.posts.read(post_id);
            assert(post.id.is_non_zero(), 'Post does not exist');

            let caller = get_caller_address();
            assert(post.author != caller, 'Cannot like own post');
            assert(!self.user_likes.read((post_id, caller)), 'Already liked');

            self.user_likes.write((post_id, caller), true);
            self.posts.write(post_id, Post { likes_count: post.likes_count + 1, ..post });

            self.emit(Event::PostLiked(PostLiked { post_id, liker: caller }));
        }

        fn get_post_author(self: @ContractState, post_id: u256) -> ContractAddress {
            let post = self.posts.read(post_id);
            assert(post.id.is_non_zero(), 'Post does not exist');
            post.author
        }

        fn get_post_likes(self: @ContractState, post_id: u256) -> u32 {
            let post = self.posts.read(post_id);
            assert(post.id.is_non_zero(), 'Post does not exist');
            post.likes_count
        }

        fn is_comment(self: @ContractState, post_id: u256) -> bool {
            let post = self.posts.read(post_id);
            assert(post.id.is_non_zero(), 'Post does not exist');
            match post.parent_post_id {
                Option::Some(_) => true,
                Option::None => false,
            }
        }
    }
}
