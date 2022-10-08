# frozen_string_literal: true

require 'csv'

# Loads or create data to start the game
module StartOrLoadGame
  def print_games_id
    puts 'Choose id: '
    contents = CSV.open('games.csv', headers: true, header_converters: :symbol)
    contents.each do |row|
      @id = row[:id]
      @user_guess = row[:user].split(' ')
      @counts_guess = row[:counter].to_i
      puts "ID: #{@id} Letters guessed: #{@user_guess} Opportunities left: #{5 - @counts_guess.to_i}"
    end
    id = gets.chomp
    load_game(id)
  end

  def create_new_game
    @id = count_total_saved_games + 1
    @computer_guess = extract_words_from_file.sample.delete!("\n").split('')
    @user_guess = Array.new(@computer_guess.length, '_ ')
    @user_guess.each { |element| print element }
  end
end

# Creates and deletes a temp file where information is saved to rewrite games.csv
module LoadGame
  def load_game(id)
    contents = CSV.open('games.csv', headers: true, header_converters: :symbol)
    saved_games = 1
    # Selects word to load considering ids. Words not selected are saved in new temp file
    contents.each do |row|
      if row[:id] == id
        load_chosen_id_game(row)
      else
        saved_games = create_temp(saved_games, row)
      end
    end
    rewrite_csv_games
  end

  def load_chosen_id_game(row)
    @id = count_total_saved_games
    @user_guess = row[:user].split(' ')
    @computer_guess = row[:computer].split(' ')
    @counts_guess = row[:counter].to_i
  end

  def create_temp(saved_games, row)
    puts 'create_temp'
    CSV.open('temp.csv', 'ab') do |csv|
      csv << %w[Id User Computer Counter] if csv.stat.zero?
      csv << [saved_games, row[:user], row[:computer], row[:counter]]
    end
    saved_games += 1
  end

  def rewrite_csv_games
    CSV.open('games.csv', 'w') do |csv|
      csv << %w[Id User Computer Counter] if csv.stat.zero?
      # Rewrites games.cvs entirely with info in temp.csv
      if File.exist?('temp.csv')
        contents = CSV.open('temp.csv', headers: true, header_converters: :symbol)
        contents.each { |row| csv << [row[:id], row[:user], row[:computer], row[:counter].to_i] }
      end
    end
    File.delete('temp.csv') if File.exist?('temp.csv')
  end
end

# Envolves all the steps related to the game once the hidden word is loaded
# It does not include loading the game
class Hangman
  include StartOrLoadGame
  include LoadGame
  attr_accessor :id, :user_guess, :computer_guess, :counts_guess

  def initialize(id, user_guess, computer_guess, counts_guess)
    @id = id
    @user_guess = user_guess
    @computer_guess = computer_guess
    @counts_guess = counts_guess
  end

  # Game ends when user guesses incorrectly 5 times or
  # When the user guesses the hidden word
  def start_guess_word
    while @counts_guess < 5 && @user_guess.join.gsub(' ', '') != @computer_guess.join
      letter = validate_guess_input
      letter_in_computer_string?(letter)
      save_game
    end
    print_final_result
  end

  # Checks if the input is a letter
  def validate_guess_input
    flag = true
    @user_guess.each { |element| print element != '_ ' ? "#{element} " : element }
    while flag
      print "\n\nChoose a letter: "
      string = gets.chomp.downcase
      flag = false if string.match?(/[[:alpha:]]/)
    end
    string
  end

  # If user's guess is not in hidden word, opportunities to guess is reduce by 1
  def letter_in_computer_string?(letter)
    if @computer_guess.include?(letter)
      @computer_guess.each_with_index { |cletter, i| user_guess[i] = cletter == letter ? "#{cletter} " : next }
      @user_guess.each { |element| print element != '_ ' ? "#{element} " : element }
    else
      @counts_guess += 1
      puts "\nLetter #{letter} is not in the word. Tries left #{5 - @counts_guess} \n"
    end
  end

  # Prints if the user won/lost the game
  def print_final_result
    if @user_guess.join.gsub(' ', '') == @computer_guess.join
      puts "You win! Guessed #{@computer_guess.join} correctly"
    elsif @counts_guess == 5
      puts "You lost! Word to guess: #{@computer_guess.join}"
    end
  end

  # Creates a CSV file that saves all the games the user want
  def save_game
    puts "\nPress 'yes' to save the game. Any other buttom to continue"
    return unless gets.chomp.upcase == 'YES'

    puts 'save_game'
    CSV.open('games.csv', 'ab') do |csv|
      csv << %w[Id User Computer Counter] if csv.stat.zero?
      csv << [@id, @user_guess.join(' '), @computer_guess.join(' '), @counts_guess]
    end
    puts "\nGame was saved"
    exit
  end
end

def extract_words_from_file
  file = File.open('google-10000-english.txt', 'r', chomp: true)
  words = []

  file.readlines.each do |word|
    next unless word.length > 5 && word.length < 12

    words.append(word)
  end
  file.close
  words
end

# Creates CSV file where games will be saved and counts number of rows (games)
def count_total_saved_games
  saved_games = 0
  CSV.open('games.csv', 'ab')
  contents = CSV.open('games.csv', headers: true, header_converters: :symbol)
  contents.each do
    saved_games += 1
  end
  saved_games
end

game = Hangman.new('', '', '', 0)

if count_total_saved_games.positive?
  puts 'Do you want to load a previous game? (yes/no)'
  decision = gets.chomp.downcase
  decision == 'yes' ? game.print_games_id : game.create_new_game
else
  game.create_new_game
end

game.start_guess_word
