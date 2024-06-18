#!/usr/bin/perl -w
my $pass = 1;
while(<ARGV>){
    if($_ =~ /error|Error|failed|Failed|UVM_FATAL|UVM_ERROR/){
        $pass = 0;
        last;
    }
    if($_ =~ /Report counts by severity/){
        last;
    }
}
if($pass == 1){
    print "\033[42;37m SIMULATION PASS! \033[0m \n";
    print_pass();
} else {
    print "\033[41;37m SIMULATION FAIL! \033[0m \n";
    print_fail();
}

sub print_pass{
    print "\n";
    print "#############           #              ##############       ##############";       print "\n";
    print "#############          ###             ##############       ##############";       print "\n";
    print "##         ##         # # #            ##                   ##";                   print "\n";
    print "##         ##        ##   ##           ##                   ##";                   print "\n";
    print "##         ##       ##      ##         ##                   ##";                   print "\n";
    print "##         ##      ##        ##        ##                   ##";                   print "\n";
    print "#############     ##############       ##############       ##############";       print "\n";
    print "#############     ##############       ##############       ##############";       print "\n";
    print "##                ##          ##                   ##                   ##";       print "\n";
    print "##                ##          ##                   ##                   ##";       print "\n";
    print "##                ##          ##                   ##                   ##";       print "\n";
    print "##                ##          ##                   ##                   ##";       print "\n";
    print "##                ##          ##       ##############       ##############";       print "\n";
    print "##                ##          ##       ##############       ##############";       print "\n";
    print "\n";
}

sub print_fail{
    print "\n";
    print "#############           #              ##############       ##";                   print "\n";
    print "#############          ###             ##############       ##";                   print "\n";
    print "##                    # # #                  ##             ##";                   print "\n";
    print "##                   ##   ##                 ##             ##";                   print "\n";
    print "##                  ##      ##               ##             ##";                   print "\n";
    print "##                 ##        ##              ##             ##";                   print "\n";
    print "#############     ##############             ##             ##";                   print "\n";
    print "#############     ##############             ##             ##";                   print "\n";
    print "##                ##          ##             ##             ##";                   print "\n";
    print "##                ##          ##             ##             ##";                   print "\n";
    print "##                ##          ##             ##             ##";                   print "\n";
    print "##                ##          ##             ##             ##";                   print "\n";
    print "##                ##          ##       ##############       ##############";       print "\n";
    print "##                ##          ##       ##############       ##############";       print "\n";
    print "\n";
}
