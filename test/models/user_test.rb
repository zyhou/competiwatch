require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'merge_with handles duplicate friends' do
    primary_user = create(:user)
    primary_account = create(:oauth_account, user: primary_user)
    friend1 = create(:friend, user: primary_user, name: 'Luis')
    match1 = create(:match, oauth_account: primary_account)
    match_friend1 = create(:match_friend, friend: friend1, match: match1)
    secondary_user = create(:user)
    secondary_account = create(:oauth_account, user: secondary_user)
    friend2 = create(:friend, user: secondary_user, name: 'Luis')
    match2 = create(:match, oauth_account: secondary_account)
    match_friend2 = create(:match_friend, friend: friend2, match: match2)

    assert_no_difference 'MatchFriend.count' do
      assert_difference 'Friend.count', -1 do
        assert secondary_user.merge_with(primary_user), 'should return true on success'
      end
    end

    assert_equal primary_user, friend1.reload.user
    refute Friend.exists?(friend2.id), 'should have deleted friend with same name'
    refute User.exists?(secondary_user.id), 'secondary user should have been deleted'
    assert_equal friend1, match_friend2.reload.friend,
      'should have replaced friend in match with existing friend of the same name'
  end

  test 'merge_with moves accounts and friends to given user' do
    primary_user = create(:user, battletag: 'PrimaryUser#123')
    secondary_user = create(:user, battletag: 'SecondaryUser#456')
    friend1 = create(:friend, user: secondary_user)
    friend2 = create(:friend, user: secondary_user)
    oauth_account1 = create(:oauth_account, user: secondary_user)
    oauth_account2 = create(:oauth_account, user: secondary_user)

    assert_no_difference ['OauthAccount.count', 'Friend.count'] do
      assert_difference 'User.count', -1 do
        assert secondary_user.merge_with(primary_user), 'should return true on success'
        assert_empty secondary_user.oauth_accounts.reload
        assert_empty secondary_user.friends.reload
      end
    end

    assert_equal primary_user, friend1.reload.user
    assert_equal primary_user, friend2.reload.user
    assert_equal primary_user, oauth_account1.reload.user
    assert_equal primary_user, oauth_account2.reload.user
    refute User.exists?(secondary_user.id), 'secondary user should have been deleted'
  end

  test 'requires battletag' do
    user = User.new

    refute_predicate user, :valid?
    assert_includes user.errors.messages[:battletag], "can't be blank"
  end

  test 'requires unique battletag' do
    user1 = create(:user)
    user2 = User.new(battletag: user1.battletag)

    refute_predicate user2, :valid?
    assert_includes user2.errors.messages[:battletag], 'has already been taken'
  end

  test 'deletes friends when deleted' do
    user = create(:user)
    friend1 = create(:friend, user: user)
    friend2 = create(:friend, user: user)

    assert_difference 'Friend.count', -2 do
      user.destroy
    end

    refute MatchFriend.exists?(friend1.id)
    refute MatchFriend.exists?(friend2.id)
  end

  test 'deletes OAuth accounts when deleted' do
    user = create(:user)
    oauth_account1 = create(:oauth_account, user: user)
    oauth_account2 = create(:oauth_account, user: user)

    assert_difference 'OauthAccount.count', -2 do
      user.destroy
    end

    refute OauthAccount.exists?(oauth_account1.id)
    refute OauthAccount.exists?(oauth_account2.id)
  end

  test "friend_names returns all user's friends when season has no matches" do
    user = create(:user)
    friend1 = create(:friend, user: user, name: 'Tamara')
    friend2 = create(:friend, user: user, name: 'Marcus')
    friend3 = create(:friend, user: user, name: 'Phillipe')

    assert_equal %w[Marcus Phillipe Tamara], user.friend_names(3)
  end

  test 'friend_names returns unique, sorted list of names from friends in matches that season' do
    user = create(:user)
    friend1 = create(:friend, user: user, name: 'Gilly')
    friend2 = create(:friend, user: user, name: 'Alice')
    friend3 = create(:friend, user: user, name: 'Zed')
    oauth_account1 = create(:oauth_account, user: user)
    oauth_account2 = create(:oauth_account, user: user)
    season = 4
    match1 = create(:match, oauth_account: oauth_account1, season: season)
    create(:match_friend, match: match1, friend: friend1)
    match2 = create(:match, oauth_account: oauth_account2, season: season)
    create(:match_friend, match: match2, friend: friend2)
    match3 = create(:match, oauth_account: oauth_account2, season: season + 1)
    create(:match_friend, match: match3, friend: friend3)
    match4 = create(:match, oauth_account: oauth_account2, season: season)
    create(:match_friend, match: match4, friend: friend2)

    result = user.friend_names(season)

    assert_includes result, friend1.name
    assert_includes result, friend2.name
    refute_includes result, friend3.name, 'should not include friend from a different season'
    assert_equal 2, result.size, 'should not return duplicate names'
  end
end
