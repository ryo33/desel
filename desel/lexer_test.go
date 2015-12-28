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
			[]Token{newTestToken(T_comment, "    ", 0)},
		},
		lexeme_test_case{
			"comment",
			[]Token{newTestToken(T_comment, "comment", 0)},
		},
		lexeme_test_case{
			" %",
			[]Token{newTestToken(T_comment, " %", 0)},
		},
		lexeme_test_case{
			" @",
			[]Token{newTestToken(T_comment, " @", 0)},
		},
	}, description)

	description = "a set/element line"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{
			"%Set @ element1  @e2  'e 3' \"e  4\" @'e 5' @\"e  6\" a@b # comment",
			[]Token{
				newTestToken(T_pre_set, "%", 0),
				newTestToken(T_label, "Set", 1),
				newTestToken(T_whitespaces, " ", 4),
				newTestToken(T_pre_element, "@", 5),
				newTestToken(T_whitespaces, " ", 6),
				newTestToken(T_label, "element1", 7),
				newTestToken(T_whitespaces, "  ", 15),
				newTestToken(T_pre_element, "@", 17),
				newTestToken(T_label, "e2", 18),
				newTestToken(T_whitespaces, "  ", 20),
				newTestToken(T_label, "'e 3'", 22),
				newTestToken(T_whitespaces, " ", 27),
				newTestToken(T_label, "\"e  4\"", 28),
				newTestToken(T_whitespaces, " ", 34),
				newTestToken(T_pre_element, "@", 35),
				newTestToken(T_label, "'e 5'", 36),
				newTestToken(T_whitespaces, " ", 41),
				newTestToken(T_pre_element, "@", 42),
				newTestToken(T_label, "\"e  6\"", 43),
				newTestToken(T_whitespaces, " ", 49),
				newTestToken(T_label, "a", 50),
				newTestToken(T_pre_element, "@", 51),
				newTestToken(T_label, "b", 52),
				newTestToken(T_whitespaces, " ", 53),
				newTestToken(T_comment, "# comment", 54),
			},
		},
		lexeme_test_case{
			"%Set %A -%b - %c ( %d(%e)%f ) (%g)!%h !%i&%j & %k#comment",
			[]Token{
				newTestToken(T_pre_set, "%", 0),
				newTestToken(T_label, "Set", 1),
				newTestToken(T_whitespaces, " ", 4),
				newTestToken(T_pre_set, "%", 5),
				newTestToken(T_label, "A", 6),
				newTestToken(T_whitespaces, " ", 7),
				newTestToken(T_minus, "-", 8),
				newTestToken(T_pre_set, "%", 9),
				newTestToken(T_label, "b", 10),
				newTestToken(T_whitespaces, " ", 11),
				newTestToken(T_minus, "-", 12),
				newTestToken(T_whitespaces, " ", 13),
				newTestToken(T_pre_set, "%", 14),
				newTestToken(T_label, "c", 15),
				newTestToken(T_whitespaces, " ", 16),
				newTestToken(T_lparen, "(", 17),
				newTestToken(T_whitespaces, " ", 18),
				newTestToken(T_pre_set, "%", 19),
				newTestToken(T_label, "d", 20),
				newTestToken(T_lparen, "(", 21),
				newTestToken(T_pre_set, "%", 22),
				newTestToken(T_label, "e", 23),
				newTestToken(T_rparen, ")", 24),
				newTestToken(T_pre_set, "%", 25),
				newTestToken(T_label, "f", 26),
				newTestToken(T_whitespaces, " ", 27),
				newTestToken(T_rparen, ")", 28),
				newTestToken(T_whitespaces, " ", 29),
				newTestToken(T_lparen, "(", 30),
				newTestToken(T_pre_set, "%", 31),
				newTestToken(T_label, "g", 32),
				newTestToken(T_rparen, ")", 33),
				newTestToken(T_not, "!", 34),
				newTestToken(T_pre_set, "%", 35),
				newTestToken(T_label, "h", 36),
				newTestToken(T_whitespaces, " ", 37),
				newTestToken(T_not, "!", 38),
				newTestToken(T_pre_set, "%", 39),
				newTestToken(T_label, "i", 40),
				newTestToken(T_and, "&", 41),
				newTestToken(T_pre_set, "%", 42),
				newTestToken(T_label, "j", 43),
				newTestToken(T_whitespaces, " ", 44),
				newTestToken(T_and, "&", 45),
				newTestToken(T_whitespaces, " ", 46),
				newTestToken(T_pre_set, "%", 47),
				newTestToken(T_label, "k", 48),
				newTestToken(T_comment, "#comment", 49),
			},
		},
		lexeme_test_case{
			"@Element % set%a",
			[]Token{
				newTestToken(T_pre_element, "@", 0),
				newTestToken(T_label, "Element", 1),
				newTestToken(T_whitespaces, " ", 8),
				newTestToken(T_pre_set, "%", 9),
				newTestToken(T_whitespaces, " ", 10),
				newTestToken(T_label, "set", 11),
				newTestToken(T_pre_set, "%", 14),
				newTestToken(T_label, "a", 15),
			},
		},
	}, description)
}

func testTokenizer(t *testing.T, test_cases []lexeme_test_case, message string) {
	for _, test_case := range test_cases {
		tokens := Tokenize([]rune(test_case.str))
		failed := func() {
			t.Errorf("failed to tokenize %s: \"%s\"", message, test_case.str)
			for _, token := range tokens {
				t.Logf("%d `%s` %d", token.category, string(token.lexeme), token.position)
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
					failed()
				}
			}
		} else {
			failed()
		}
	}
}

func newTestToken(category int, lexeme string, position int) Token {
	return Token{category, []rune(lexeme), position}
}
