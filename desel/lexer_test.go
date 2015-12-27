package desel

import (
	"testing"
)

type lexeme_test_case struct {
	str    string
	tokens []token
}

func TestTokenizer(t *testing.T) {
	description := "an empty string"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{"", []token{}},
	}, description)

	description = "a comment line"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{
			"    ",
			[]token{newTestToken(t_comment, "    ", 0)},
		},
		lexeme_test_case{
			"comment",
			[]token{newTestToken(t_comment, "comment", 0)},
		},
		lexeme_test_case{
			" %",
			[]token{newTestToken(t_comment, " %", 0)},
		},
		lexeme_test_case{
			" @",
			[]token{newTestToken(t_comment, " @", 0)},
		},
	}, description)

	description = "a set/element line"
	testTokenizer(t, []lexeme_test_case{
		lexeme_test_case{
			"%Set @ element1  @e2  'e 3' \"e  4\" @'e 5' @\"e  6\" a@b # comment",
			[]token{
				newTestToken(t_pre_set, "%", 0),
				newTestToken(t_label, "Set", 1),
				newTestToken(t_whitespaces, " ", 4),
				newTestToken(t_pre_element, "@", 5),
				newTestToken(t_whitespaces, " ", 6),
				newTestToken(t_label, "element1", 7),
				newTestToken(t_whitespaces, "  ", 15),
				newTestToken(t_pre_element, "@", 17),
				newTestToken(t_label, "e2", 18),
				newTestToken(t_whitespaces, "  ", 20),
				newTestToken(t_label, "'e 3'", 22),
				newTestToken(t_whitespaces, " ", 27),
				newTestToken(t_label, "\"e  4\"", 28),
				newTestToken(t_whitespaces, " ", 34),
				newTestToken(t_pre_element, "@", 35),
				newTestToken(t_label, "'e 5'", 36),
				newTestToken(t_whitespaces, " ", 41),
				newTestToken(t_pre_element, "@", 42),
				newTestToken(t_label, "\"e  6\"", 43),
				newTestToken(t_whitespaces, " ", 49),
				newTestToken(t_label, "a", 50),
				newTestToken(t_pre_element, "@", 51),
				newTestToken(t_label, "b", 52),
				newTestToken(t_whitespaces, " ", 53),
				newTestToken(t_comment, "# comment", 54),
			},
		},
		lexeme_test_case{
			"%Set %A -%b - %c ( %d(%e)%f ) (%g)!%h !%i&%j & %k#comment",
			[]token{
				newTestToken(t_pre_set, "%", 0),
				newTestToken(t_label, "Set", 1),
				newTestToken(t_whitespaces, " ", 4),
				newTestToken(t_pre_set, "%", 5),
				newTestToken(t_label, "A", 6),
				newTestToken(t_whitespaces, " ", 7),
				newTestToken(t_minus, "-", 8),
				newTestToken(t_pre_set, "%", 9),
				newTestToken(t_label, "b", 10),
				newTestToken(t_whitespaces, " ", 11),
				newTestToken(t_minus, "-", 12),
				newTestToken(t_whitespaces, " ", 13),
				newTestToken(t_pre_set, "%", 14),
				newTestToken(t_label, "c", 15),
				newTestToken(t_whitespaces, " ", 16),
				newTestToken(t_lparen, "(", 17),
				newTestToken(t_whitespaces, " ", 18),
				newTestToken(t_pre_set, "%", 19),
				newTestToken(t_label, "d", 20),
				newTestToken(t_lparen, "(", 21),
				newTestToken(t_pre_set, "%", 22),
				newTestToken(t_label, "e", 23),
				newTestToken(t_rparen, ")", 24),
				newTestToken(t_pre_set, "%", 25),
				newTestToken(t_label, "f", 26),
				newTestToken(t_whitespaces, " ", 27),
				newTestToken(t_rparen, ")", 28),
				newTestToken(t_whitespaces, " ", 29),
				newTestToken(t_lparen, "(", 30),
				newTestToken(t_pre_set, "%", 31),
				newTestToken(t_label, "g", 32),
				newTestToken(t_rparen, ")", 33),
				newTestToken(t_not, "!", 34),
				newTestToken(t_pre_set, "%", 35),
				newTestToken(t_label, "h", 36),
				newTestToken(t_whitespaces, " ", 37),
				newTestToken(t_not, "!", 38),
				newTestToken(t_pre_set, "%", 39),
				newTestToken(t_label, "i", 40),
				newTestToken(t_and, "&", 41),
				newTestToken(t_pre_set, "%", 42),
				newTestToken(t_label, "j", 43),
				newTestToken(t_whitespaces, " ", 44),
				newTestToken(t_and, "&", 45),
				newTestToken(t_whitespaces, " ", 46),
				newTestToken(t_pre_set, "%", 47),
				newTestToken(t_label, "k", 48),
				newTestToken(t_comment, "#comment", 49),
			},
		},
		lexeme_test_case{
			"@Element % set%a",
			[]token{
				newTestToken(t_pre_element, "@", 0),
				newTestToken(t_label, "Element", 1),
				newTestToken(t_whitespaces, " ", 8),
				newTestToken(t_pre_set, "%", 9),
				newTestToken(t_whitespaces, " ", 10),
				newTestToken(t_label, "set", 11),
				newTestToken(t_pre_set, "%", 14),
				newTestToken(t_label, "a", 15),
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

func newTestToken(category int, lexeme string, position int) token {
	return token{category, []rune(lexeme), position}
}
