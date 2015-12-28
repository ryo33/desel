package desel

type Token struct {
	category int
	lexeme   []rune
	position int
}

const (
	T_comment     = iota
	T_whitespaces = iota
	T_pre_set     = iota
	T_pre_element = iota
	T_label       = iota
	T_lparen      = iota
	T_rparen      = iota
	T_and         = iota
	T_minus       = iota
	T_not         = iota
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

func append_pre_set()     { append_token(T_pre_set, []rune{pre_set}, position); position++ }
func append_pre_element() { append_token(T_pre_element, []rune{pre_element}, position); position++ }
func append_lparen()      { append_token(T_lparen, []rune{lparen}, position); position++ }
func append_rparen()      { append_token(T_rparen, []rune{rparen}, position); position++ }
func append_and()         { append_token(T_and, []rune{and}, position); position++ }
func append_minus()       { append_token(T_minus, []rune{minus}, position); position++ }
func append_not()         { append_token(T_not, []rune{not}, position); position++ }

var (
	position int // current position
	tokens   []Token
	length   int
	get_next func() rune
	slice    func(int, int) []rune
)

func Tokenize(str []rune) []Token {
	position = 0
	tokens = []Token{}
	length = len(str)
	get_next = func() rune { return str[position] }
	slice = func(start int, end int) []rune {
		return str[start:end]
	}
	if length == 0 {
		return tokens
	}
	switch str[0] {
	case pre_set:
		append_pre_set()
	case pre_element:
		append_pre_element()
	default:
		append_token(T_comment, str, position)
		return tokens
	}
	for position < length {
		switch get_next() {
		case pre_comment:
			append_token(T_comment, str[position:length], position)
			return tokens
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
	return tokens
}

func append_whitespaces() {
	start := position
	position++
	for ; position < length; position++ {
		if c := get_next(); c != tab && c != space {
			break
		}
	}
	append_token(T_whitespaces, slice(start, position), start)
}

func append_label() {
	start := position
	switch get_next() {
	case s_quote:
		position++
		consume_until(func(c rune) bool { return c != s_quote })
		position++
	case d_quote:
		position++
		consume_until(func(c rune) bool { return c != d_quote })
		position++
	default:
		position++
		consume_until(func(c rune) bool {
			switch c {
			case pre_comment, pre_set, pre_element, lparen, rparen, and, minus, not, tab, space:
				return false
			default:
				return true
			}
		})
		// position ++ is ununnecessary
	}
	append_token(T_label, slice(start, position), start)
}

func consume_until(until func(rune) bool) {
	for ; position < length && until(get_next()); position++ {
	}
}

func append_token(category int, lexeme []rune, position int) {
	tokens = append(tokens, Token{category, lexeme, position})
}
