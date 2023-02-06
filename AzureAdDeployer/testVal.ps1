$script:val = 0
function foo() {
    $script:val = 10
}
foo
write "The number is: $script:val"
