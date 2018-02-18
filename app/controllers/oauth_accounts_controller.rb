class OauthAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_oauth_account, only: :destroy
  before_action :ensure_oauth_account_is_mine, only: :destroy
  before_action :set_season, only: :stats

  def stats
    @total_matches = current_user.matches.with_result.in_season(@season).count

    matches = current_user.matches.includes(:friends, :heroes).in_season(@season).with_result.
      ordered_by_time

    @total_accounts = matches.map(&:oauth_account_id).uniq.size
    @total_wins = matches.select(&:win?).size
    @total_losses = matches.select(&:loss?).size
    @total_draws = matches.select(&:draw?).size

    @match_counts_by_hero = matches.inject({}) do |hash, match|
      match.heroes.each do |hero|
        hash[hero] ||= 0
        hash[hero] += 1
      end
      hash
    end
    @match_counts_by_hero = @match_counts_by_hero.sort_by { |_hero, count| -count }.to_h
    @max_hero_match_count = @match_counts_by_hero.values.first

    all_ranks = matches.select { |match| match.season > 1 }.map(&:rank).sort
    @lowest_sr = all_ranks.min
    @highest_sr = all_ranks.max
  end

  def index
    @oauth_accounts = current_user.oauth_accounts.includes(:user).order_by_battletag
  end

  def destroy
    unless @oauth_account.can_be_unlinked?
      flash[:error] = "#{@oauth_account} cannot be unlinked from your account."
      return redirect_to(accounts_path)
    end

    @oauth_account.user = nil
    if @oauth_account.save
      flash[:notice] = "Successfully disconnected #{@oauth_account}."
    else
      flash[:error] = "Could not disconnect #{@oauth_account}."
    end
    redirect_to accounts_path
  end
end
