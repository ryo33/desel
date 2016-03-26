package desel

import (
	"testing"
)

type lexeme_test_case struct {
	str    string
	tokens []Token
}

func TestTokenizer(t *testing.T) {
	description := "an empty string"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{"", []Token{}},
	}, description)

	description = "a comment line"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{
			"    ",
			[]Token{newTestToken(T_comment, "    ", 0, 0)},
		},
		lexeme_test_case{
			"comment",
			[]Token{newTestToken(T_comment, "comment", 0, 0)},
		},
		lexeme_test_case{
			" %",
			[]Token{newTestToken(T_comment, " %", 0, 0)},
		},
		lexeme_test_case{
			" @",
			[]Token{newTestToken(T_comment, " @", 0, 0)},
		},
	}, description)

	description = "a set/element line"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{
			"%Set @ element1  @e2  'e 3' \"e  4\" @'e 5' @\"e  6\" a@b # comment",
			[]Token{
				newTestToken(T_pre_set, "%", 0, 0),
				newTestToken(T_label, "Set", 1, 0),
				newTestToken(T_whitespaces, " ", 4, 0),
				newTestToken(T_pre_element, "@", 5, 0),
				newTestToken(T_whitespaces, " ", 6, 0),
				newTestToken(T_label, "element1", 7, 0),
				newTestToken(T_whitespaces, "  ", 15, 0),
				newTestToken(T_pre_element, "@", 17, 0),
				newTestToken(T_label, "e2", 18, 0),
				newTestToken(T_whitespaces, "  ", 20, 0),
				newTestToken(T_label, "'e 3'", 22, 0),
				newTestToken(T_whitespaces, " ", 27, 0),
				newTestToken(T_label, "\"e  4\"", 28, 0),
				newTestToken(T_whitespaces, " ", 34, 0),
				newTestToken(T_pre_element, "@", 35, 0),
				newTestToken(T_label, "'e 5'", 36, 0),
				newTestToken(T_whitespaces, " ", 41, 0),
				newTestToken(T_pre_element, "@", 42, 0),
				newTestToken(T_label, "\"e  6\"", 43, 0),
				newTestToken(T_whitespaces, " ", 49, 0),
				newTestToken(T_label, "a", 50, 0),
				newTestToken(T_pre_element, "@", 51, 0),
				newTestToken(T_label, "b", 52, 0),
				newTestToken(T_whitespaces, " ", 53, 0),
				newTestToken(T_comment, "# comment", 54, 0),
			},
		},
		lexeme_test_case{
			"%Set %A -%b - %c ( %d(%e)%f ) (%g)!%h !%i&%j & %k#comment",
			[]Token{
				newTestToken(T_pre_set, "%", 0, 0),
				newTestToken(T_label, "Set", 1, 0),
				newTestToken(T_whitespaces, " ", 4, 0),
				newTestToken(T_pre_set, "%", 5, 0),
				newTestToken(T_label, "A", 6, 0),
				newTestToken(T_whitespaces, " ", 7, 0),
				newTestToken(T_minus, "-", 8, 0),
				newTestToken(T_pre_set, "%", 9, 0),
				newTestToken(T_label, "b", 10, 0),
				newTestToken(T_whitespaces, " ", 11, 0),
				newTestToken(T_minus, "-", 12, 0),
				newTestToken(T_whitespaces, " ", 13, 0),
				newTestToken(T_pre_set, "%", 14, 0),
				newTestToken(T_label, "c", 15, 0),
				newTestToken(T_whitespaces, " ", 16, 0),
				newTestToken(T_lparen, "(", 17, 0),
				newTestToken(T_whitespaces, " ", 18, 0),
				newTestToken(T_pre_set, "%", 19, 0),
				newTestToken(T_label, "d", 20, 0),
				newTestToken(T_lparen, "(", 21, 0),
				newTestToken(T_pre_set, "%", 22, 0),
				newTestToken(T_label, "e", 23, 0),
				newTestToken(T_rparen, ")", 24, 0),
				newTestToken(T_pre_set, "%", 25, 0),
				newTestToken(T_label, "f", 26, 0),
				newTestToken(T_whitespaces, " ", 27, 0),
				newTestToken(T_rparen, ")", 28, 0),
				newTestToken(T_whitespaces, " ", 29, 0),
				newTestToken(T_lparen, "(", 30, 0),
				newTestToken(T_pre_set, "%", 31, 0),
				newTestToken(T_label, "g", 32, 0),
				newTestToken(T_rparen, ")", 33, 0),
				newTestToken(T_not, "!", 34, 0),
				newTestToken(T_pre_set, "%", 35, 0),
				newTestToken(T_label, "h", 36, 0),
				newTestToken(T_whitespaces, " ", 37, 0),
				newTestToken(T_not, "!", 38, 0),
				newTestToken(T_pre_set, "%", 39, 0),
				newTestToken(T_label, "i", 40, 0),
				newTestToken(T_and, "&", 41, 0),
				newTestToken(T_pre_set, "%", 42, 0),
				newTestToken(T_label, "j", 43, 0),
				newTestToken(T_whitespaces, " ", 44, 0),
				newTestToken(T_and, "&", 45, 0),
				newTestToken(T_whitespaces, " ", 46, 0),
				newTestToken(T_pre_set, "%", 47, 0),
				newTestToken(T_label, "k", 48, 0),
				newTestToken(T_comment, "#comment", 49, 0),
			},
		},
		lexeme_test_case{
			"@Element % set%a",
			[]Token{
				newTestToken(T_pre_element, "@", 0, 0),
				newTestToken(T_label, "Element", 1, 0),
				newTestToken(T_whitespaces, " ", 8, 0),
				newTestToken(T_pre_set, "%", 9, 0),
				newTestToken(T_whitespaces, " ", 10, 0),
				newTestToken(T_label, "set", 11, 0),
				newTestToken(T_pre_set, "%", 14, 0),
				newTestToken(T_label, "a", 15, 0),
			},
		},
		lexeme_test_case{
			"a\n" +
				"@Element % set%a\n" +
				"comment\n" +
				" %\n" +
				" @",
			[]Token{
				newTestToken(T_comment, "a", 0, 0),
				newTestToken(T_newline, "\n", 1, 0),
				newTestToken(T_pre_element, "@", 0, 1),
				newTestToken(T_label, "Element", 1, 1),
				newTestToken(T_whitespaces, " ", 8, 1),
				newTestToken(T_pre_set, "%", 9, 1),
				newTestToken(T_whitespaces, " ", 10, 1),
				newTestToken(T_label, "set", 11, 1),
				newTestToken(T_pre_set, "%", 14, 1),
				newTestToken(T_label, "a", 15, 1),
				newTestToken(T_newline, "\n", 16, 1),
				newTestToken(T_comment, "comment", 0, 2),
				newTestToken(T_newline, "\n", 7, 2),
				newTestToken(T_comment, " %", 0, 3),
				newTestToken(T_newline, "\n", 2, 3),
				newTestToken(T_comment, " @", 0, 4),
			},
		},
	}, description)
}

func testTokenizer(t *testing.T, test_cases []lexeme_test_case, message string) {
	for _, test_case := range test_cases {
		tokens := Tokenize(test_case.str)
		failed := func() {
			t.Errorf("failed to tokenize %s: \"%s\"", message, test_case.str)
			for _, token := range tokens {
				t.Logf("%d `%s` %d %d", token.category, string(token.lexeme), token.position, token.line)
			}
		}
		if len(tokens) == len(test_case.tokens) {
			for i := 0; i < len(tokens); i++ {
				switch {
				case tokens[i].category != test_case.tokens[i].category:
					fallthrough
				case string(tokens[i].lexeme) != string(test_case.tokens[i].lexeme):
					fallthrough
				case tokens[i].position != test_case.tokens[i].position:
					fallthrough
				case tokens[i].line != test_case.tokens[i].line:
					failed()
				}
			}
		} else {
			failed()
		}
	}
}

func newTestToken(category int, lexeme string, position int, line int) Token {
	return Token{category, []rune(lexeme), position, line}
}
