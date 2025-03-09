use snforge_std::{CheatSpan, ContractClassTrait, DeclareResultTrait, cheat_caller_address, declare};
use social_network::post::{IPostDispatcher, IPostDispatcherTrait};
use starknet::{ContractAddress, get_contract_address};

fn setup() -> ContractAddress {
    let social_post_class = declare("SocialPost").unwrap().contract_class();
    let (contract_address, _) = social_post_class.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_create_post() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };

    // Test initial post creation
    let post_id = social_post.create_post();
    assert!(post_id == 1, "First post should be ID 1");

    // Verify post data
    let author = social_post.get_post_author(post_id);
    let caller: ContractAddress = get_contract_address();
    assert!(author == caller, "Author should match caller");

    let likes = social_post.get_post_likes(post_id);
    assert!(likes == 0, "Initial likes should be 0");

    let is_comment = social_post.is_comment(post_id);
    assert!(!is_comment, "New post should not be a comment");
}

#[test]
fn test_create_comment() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };

    // Create parent post
    let parent_id = social_post.create_post();

    // Create comment
    let comment_id = social_post.create_comment(parent_id);
    assert!(comment_id == 2, "Comment should be ID 2");

    // Verify comment data
    let is_comment = social_post.is_comment(comment_id);
    assert!(is_comment, "Should be a comment");

    let parent_author = social_post.get_post_author(parent_id);
    let comment_author = social_post.get_post_author(comment_id);
    assert!(parent_author == comment_author, "Authors should match");
}

#[test]
#[should_panic(expected: ('Parent post does not exist',))]
fn test_create_comment_invalid_parent() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };

    social_post.create_comment(999); // Non-existent parent ID
}

#[test]
fn test_like_post() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };
    let post_id = social_post.create_post();

    // Switch to different user for liking
    let liker: ContractAddress = 456.try_into().unwrap();
    cheat_caller_address(social_post.contract_address, liker, CheatSpan::TargetCalls(1));

    social_post.like_post(post_id);

    let likes = social_post.get_post_likes(post_id);
    assert(likes == 1, 'Likes should increment');
}

#[test]
#[should_panic(expected: ('Cannot like own post',))]
fn test_like_own_post() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };
    let post_id = social_post.create_post();

    // Try to like own post
    social_post.like_post(post_id);
}

#[test]
#[should_panic(expected: ('Already liked',))]
fn test_double_like() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };
    let post_id = social_post.create_post();

    let liker: ContractAddress = 456.try_into().unwrap();
    cheat_caller_address(social_post.contract_address, liker, CheatSpan::TargetCalls(2));

    social_post.like_post(post_id);
    social_post.like_post(post_id); // Second like should fail
}

#[test]
fn test_multiple_likes() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };
    let post_id = social_post.create_post();

    // First liker
    let liker1: ContractAddress = 111.try_into().unwrap();
    cheat_caller_address(social_post.contract_address, liker1, CheatSpan::TargetCalls(1));
    social_post.like_post(post_id);

    // Second liker
    let liker2: ContractAddress = 222.try_into().unwrap();
    cheat_caller_address(social_post.contract_address, liker2, CheatSpan::TargetCalls(1));
    social_post.like_post(post_id);

    let likes = social_post.get_post_likes(post_id);
    assert(likes == 2, 'Should have 2 likes');
}

#[test]
#[should_panic(expected: ('Post does not exist',))]
fn test_invalid_post_access() {
    let contract_address = setup();
    let social_post = IPostDispatcher { contract_address };

    social_post.get_post_author(999); // Non-existent post ID
}
