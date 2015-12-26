package desel

import (
	"io/ioutil"
	"os"
	"strings"
	"testing"
)

func fatal(t *testing.T, err interface{}) {
	if err != nil {
		t.Fatal(err)
	}
}

func TestReadDeselFiles(t *testing.T) {
	// Prepare files
	f1, err := ioutil.TempFile("", "1")
	fatal(t, err)
	name1 := f1.Name()
	defer os.Remove(name1)
	f2, err := ioutil.TempFile("", "2")
	fatal(t, err)
	name2 := f2.Name()
	defer os.Remove(name2)
	// Write to files
	contents1 := []string{"c1l1", "c1l2"}
	contents2 := []string{"c2l1", "c2l2", "c2l3"}
	_, err = f1.WriteString(strings.Join(contents1, "\n"))
	fatal(t, err)
	_, err = f2.WriteString(strings.Join(contents2, "\n"))
	fatal(t, err)
	// Write files
	fatal(t, f1.Close())
	fatal(t, f2.Close())
	// Test
	ds := ReadDeselFiles([]string{name1, name2})
	if len(ds) != 2 {
		t.Error("wrong number of desel files: %d", len(ds))
	}
	testReadDesel(t, ds[0], name1, contents1)
	testReadDesel(t, ds[1], name2, contents2)
}

func TestReadDesel(t *testing.T) {
	contents := []string{"This is a test",
		"%Test test",
		"@test Test2",
		""}
	desc := "testing"
	r := strings.NewReader(strings.Join(contents[:], "\n"))
	d := ReadDesel(desc, r)
	testReadDesel(t, d, desc, contents)
}

func testReadDesel(t *testing.T, desel deselFile, desc string, contents []string) {
	if desel.desc != desc {
		t.Errorf("wrong desc: %s", desel.desc)
	}
	if len(desel.contents) != len(contents) {
		t.Errorf("wrong number of lines: %d", len(desel.contents))
	}
	for i, l := range contents {
		if desel.contents[i] != l {
			t.Errorf("wrong string in line %d: %s", i, desel.contents[i])
		}
	}
}
