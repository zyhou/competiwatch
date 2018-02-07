class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_oauth_account, only: [:index, :create]
  before_action :set_season, only: [:index, :create]
  before_action :set_match, only: [:edit, :update]

  def index
    @maps = get_maps
    @heroes = get_heroes
    @matches = @oauth_account.matches.in_season(@season).
      includes(:prior_match, :heroes, :map).ordered_by_time

    set_streaks(@matches)
    @longest_win_streak = @matches.map(&:win_streak).compact.max
    @longest_loss_streak = @matches.map(&:loss_streak).compact.max

    @latest_match = @matches.last

    placement_log_match = @matches.placement_logs.first
    @placement_rank = if placement_log_match
      placement_log_match.rank
    else
      last_placement = @oauth_account.last_placement_match_in(@season)
      last_placement.rank if last_placement
    end

    placement = !@oauth_account.finished_placements?(@season)
    @match = @oauth_account.matches.new(prior_match: @latest_match, season: @season,
                                        placement: placement)
  end

  def create
    @match = @oauth_account.matches.new(match_params)
    @match.season = @season

    unless @match.save
      @maps = get_maps
      @heroes = get_heroes
      @latest_match = @oauth_account.matches.ordered_by_time.last

      return render('matches/edit')
    end

    @match.set_heroes_from_ids(params[:heroes])

    redirect_to matches_path(@season, @oauth_account)
  end

  def edit
    @latest_match = @match.oauth_account.matches.ordered_by_time.last
    @maps = get_maps
    @heroes = get_heroes
  end

  def update
    @match.assign_attributes(match_params)

    unless @match.save
      @maps = get_maps
      @heroes = get_heroes
      @latest_match = @match.oauth_account.matches.ordered_by_time.last

      return render('matches/edit')
    end

    @match.set_heroes_from_ids(params[:heroes])

    redirect_to matches_path(@match.season, @match.oauth_account)
  end

  private

  def match_params
    params.require(:match).permit(:map_id, :rank, :comment, :prior_match_id, :placement,
                                  :result, :time_of_day, :day_of_week, :season)
  end

  def set_match
    @match = Match.where(id: params[:id]).first
    unless @match && @match.user == current_user
      render file: Rails.root.join('public', '404.html'), status: :not_found
    end
  end

  def set_streaks(matches)
    matches.each do |match|
      match.win_streak = Match.get_win_streak(match)
      match.loss_streak = Match.get_loss_streak(match)
    end
  end

  def get_maps
    Rails.cache.fetch('maps') { Map.order(:name).select([:id, :name]) }
  end

  def get_heroes
    Rails.cache.fetch('heroes') { Hero.order(:name) }
  end
end
