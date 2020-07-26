let jokes = [
    'Two bytes meet. The first byte asks, “Are you ill?” The second byte replies “No, just feeling a bit off.”',
    'There are only 10 kinds of people in this world: those who know binary and those who don’t.',
    'The generation of random numbers is too important to be left to chance.',
    'The computer is mightier than the pen, the sword, and usually, the programmer.',
    'Three very dangerous things: a programmer with a soldering iron, a hardware engineer with a software patch, and a user with an idea.',
    'How computers are like men: They have a lot of data, but are still clueless.',
    'How computers are like men: They are supposed to help you solve problems, but half the time they are the problem.',
    'How computers are like men: As soon as you commit to one, you realize that if you had waited a little longer, you could have had a better model.',
    'How computers are like women: No one but the Creator understands their internal logic.',
    'How computers are like women: The native language they use to communicate with other computers is incomprehensible to everyone else.',
    'How computers are like women: Even your smallest mistakes are stored in long-term memory for later retrieval.',
    'First Law of Computer Programming: Any given program, when running, is obsolete.',
    'Second Law of Computer Programming: Any given program costs more and takes longer.',
    'Third Law of Computer Programming: If a program is useful, it will have to be changed.',
    'Fourth Law of Computer Programming: If a program is useless, it will have to be documented.',
    'Fifth Law of Computer Programming: Any program will expand to fill available memory.',
    'Sixth Law of Computer Programming: The value of a program is proportional to the weight of its output.',
    'Seventh Law of Programming: Program complexity grows until it exceeds the capabilities of the programmer who must maintain it.',
    'Eighth Law of Computer Programming: Any non-trivial program contains at least one bug.',
    'Ninth Law of Computer Programming: Undetectable errors are infinite in variety, in contrast to detectable errors, which by definition are limited.',
    'Tenth Law of Computer Programming: Adding manpower to a late software project makes it later.',
]

function updateJoke() {
    let bird = document.getElementById('bubble');
    // let seconds = new Date().getSeconds();
    let rand = Math.floor(Math.random() * 21) + 1;
    bird.innerHTML = jokes[rand - 1];
}