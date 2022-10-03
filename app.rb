# frozen_string_literal: true

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

def start_guess_word(user_guess, computer_guess, counts_guess = 0)
  while counts_guess < 5 || user_guess == computer_guess
    letter = validate_guess_input
    user_guess, counts_guess = letter_in_computer_string?(letter, computer_guess, user_guess, counts_guess)
    user_guess.each { |element| print element != '_ ' ? "#{element} " : element }
  end
  print_final_result(user_guess, computer_guess, counts_guess)
end

def validate_guess_input
  flag = true
  while flag
    print "\n\nChoose a letter: "
    string = gets.chomp.downcase
    flag = false if string.match?(/[[:alpha:]]/)
  end
  string
end

def letter_in_computer_string?(letter, computer_guess, user_guess, counts_guess)
  if computer_guess.include?(letter)
    computer_guess.each_with_index { |cletter, i| user_guess[i] = cletter == letter ? cletter : next }
  else
    counts_guess += 1
    puts "\nLetter #{letter} is not in the word. Tries left #{5 - counts_guess} \n"
  end
  [user_guess, counts_guess]
end

def print_final_result(user_guess, computer_guess, counts_guess)
  if user_guess == computer_guess
    puts "You win! Guessed #{computer_guess.join} correctly"
  elsif counts_guess == 5
    puts "You lost! Word to guess: #{computer_guess.join}"
  end
end

computer_guess = extract_words_from_file.sample.delete!("\n").split('')

user_guess = Array.new(computer_guess.length, '_ ')
user_guess.each { |element| print element }

start_guess_word(user_guess, computer_guess)
