package desel

import (
	"strings"
)

type Token struct {
	category int
	lexeme   []rune
	column   int
	line     int
}

const (
	T_comment = iota
	T_whitespaces
	T_pre_set
	T_pre_element
	T_label
	T_lparen
	T_rparen
	T_and
	T_minus
	T_not
	T_newline
)

const (
	pre_comment = '#'
	pre_set     = '%'
	pre_element = '@'
	lparen      = '('
	rparen      = ')'
	and         = '&'
	minus       = '-'
	not         = '!'
	tab         = '\t'
	space       = ' '
	s_quote     = '\''
	d_quote     = '"'
)

func append_pre_set() { append_token(T_pre_set, []rune{pre_set}, column, line); column++ }
func append_pre_element() {
	append_token(T_pre_element, []rune{pre_element}, column, line)
	column++
}
func append_lparen() { append_token(T_lparen, []rune{lparen}, column, line); column++ }
func append_rparen() { append_token(T_rparen, []rune{rparen}, column, line); column++ }
func append_and()    { append_token(T_and, []rune{and}, column, line); column++ }
func append_minus()  { append_token(T_minus, []rune{minus}, column, line); column++ }
func append_not()    { append_token(T_not, []rune{not}, column, line); column++ }

var (
	column   int // current column
	line     int // current line
	tokens   []Token
	length   int
	get_next func() rune
	slice    func(int, int) []rune
)

func Tokenize(str string) []Token {
	line = 0
	tokens = []Token{}
	lines := strings.Split(str, "\n")
	for i, l := range lines {
		line = i
		if i != 0 {
			append_token(T_newline, []rune{'\n'}, length, line-1) // length from TokenizeLine
		}
		TokenizeLine([]rune(l))
	}
	return tokens
}

func TokenizeLine(str []rune) {
	column = 0
	length = len(str)
	get_next = func() rune { return str[column] }
	slice = func(start int, end int) []rune {
		return str[start:end]
	}
	if length == 0 {
		return
	}
	switch str[0] {
	case pre_set:
		append_pre_set()
	case pre_element:
		append_pre_element()
	default:
		append_token(T_comment, str, column, line)
		return
	}
	for column < length {
		switch get_next() {
		case pre_comment:
			append_token(T_comment, str[column:length], column, line)
			return
		case pre_set:
			append_pre_set()
		case pre_element:
			append_pre_element()
		case lparen:
			append_lparen()
		case rparen:
			append_rparen()
		case and:
			append_and()
		case minus:
			append_minus()
		case not:
			append_not()
		case tab, space:
			append_whitespaces()
		default:
			append_label()
		}
	}
}

func append_whitespaces() {
	start := column
	column++
	for ; column < length; column++ {
		if c := get_next(); c != tab && c != space {
			break
		}
	}
	append_token(T_whitespaces, slice(start, column), start, line)
}

func append_label() {
	start := column
	switch get_next() {
	case s_quote:
		column++
		consume_until(func(c rune) bool { return c != s_quote })
		column++
	case d_quote:
		column++
		consume_until(func(c rune) bool { return c != d_quote })
		column++
	default:
		column++
		consume_until(func(c rune) bool {
			switch c {
			case pre_comment, pre_set, pre_element, lparen, rparen, and, minus, not, tab, space:
				return false
			default:
				return true
			}
		})
		// column ++ is ununnecessary
	}
	append_token(T_label, slice(start, column), start, line)
}

func consume_until(until func(rune) bool) {
	for ; column < length && until(get_next()); column++ {
	}
}

func append_token(category int, lexeme []rune, column int, line int) {
	tokens = append(tokens, Token{category, lexeme, column, line})
}
