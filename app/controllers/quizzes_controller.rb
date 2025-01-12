class QuizzesController < ApplicationController
  skip_before_action :require_login, only: %i[index music_theory rhythm]
  def index; end

  def music_theory
    @quizzes = Quiz.where(quiz_type: 'music_theory').order('quiz_rank DESC')
  end

  def rhythm
    @quizzes = Quiz.where(quiz_type: 'rhythm').order('quiz_rank DESC')
  end

  def show
    @quiz = Quiz.find(params[:id])
    if UserQuiz.where(user_id: current_user.id, quiz_id: @quiz.id).exists?
      redirect_to send("#{@quiz.quiz_type}_quizzes_path")
    end
    UserQuiz.find_or_create_by(user_id: current_user.id, quiz_id: @quiz.id)
    @choices = Choice.where(quiz_id: @quiz.id)
  end

  def create
    @quiz = Quiz.find(params[:id])
    session[:correct] = params[:correct]
    clear = session[:correct] == 'true'
    if clear
      Result.create(user_id: current_user.id, quiz_type: @quiz.quiz_type, rank_score: @quiz.quiz_rank, clear: true)
    else
      Result.create(user_id: current_user.id, quiz_type: @quiz.quiz_type, rank_score: @quiz.quiz_rank, clear: false)
    end
    redirect_to result_quiz_path(@quiz)
  end

  def result
    @quiz = Quiz.find(params[:id])
    clear = session[:correct]

    number = current_user.results.where(quiz_type: @quiz.quiz_type, clear: true).maximum(:rank_score) || 0

    if number == 5
      @user_rank = 'S'
      @rank_class = 's'
    elsif number == 4
      @user_rank = 'A'
      @rank_class = 'a'
    elsif number == 3
      @user_rank = 'B'
      @rank_class = 'b'
    elsif number == 2
      @user_rank = 'C'
      @rank_class = 'c'
    elsif number == 1
      @user_rank = 'D'
      @rank_class = 'd'
    else
      @user_rank = 'E'
      @rank_class = 'e'
    end

    @result = if clear == 'true'
                '正解！'
              elsif clear == 'false'
                '不正解…'
              else
                ''
              end

    @quiz_users = User.joins(:results)
                      .where.not(id: current_user.id)
                      .where(results: { quiz_type: @quiz.quiz_type, clear: true })
                      .group('users.id')
                      .having('MAX(results.rank_score) >= ?', @quiz.quiz_rank)
                      .select('users.*, MAX(results.rank_score) AS max_rank_score')
                      .order('max_rank_score DESC')
    session.delete(:correct)
  end
end
