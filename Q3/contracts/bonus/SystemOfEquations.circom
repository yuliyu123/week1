pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/binsum.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib-matrix/circuits/matMul.circom";

template Sum() {
    signal input a; //private
    signal input b;
    signal output out;

    var i;

    component n2ba = Num2Bits(32);
    component n2bb = Num2Bits(32);
    component sum = BinSum(32,2);
    component b2n = Bits2Num(32);

    n2ba.in <== a;
    n2bb.in <== b;

    for (i=0; i<32; i++) {
        sum.in[0][i] <== n2ba.out[i];
        sum.in[1][i] <== n2bb.out[i];
    }

    for (i=0; i<32; i++) {
        b2n.in[i] <== sum.out[i];
    }

    out <== b2n.out;
}


template SystemOfEquations(n) { // n is the number of variables in the system of equations
    signal input x[n]; // this is the solution to the system of equations
    signal input A[n][n]; // this is the coefficient matrix
    signal input b[n]; // this are the constants in the system of equations
    signal output out; // 1 for correct solution, 0 for incorrect solution

    // [bonus] insert your code here

    // matMul(m,n,p);
    // A->[m,n], x->[n,p], b->[m,p] ==> Ax = b
    // system of (linear) equations
    component mul = matMul(n,n,1);
    for (var i=0; i<n; i++) {
        for (var j=0; j<n; j++) {
            mul.a[i][j] <== A[i][j];
        }
        mul.b[i][0] <== x[i];
    }

    component ieBoard[n];
    for (var i=0; i<n; i++) {
        ieBoard[i] = IsEqual();
        ieBoard[i].in[0] <== mul.out[i][0];
        ieBoard[i].in[1] <== b[i];
        ieBoard[i].out === 1;
    }

    // A->[1,n], x->[n,1], b->[1,1] ==> Ax = b
    component mulSum = matMul(1,n,1);
    for (var i=0; i<n; i++) {
        mulSum.a[0][i] <== 1;
        mulSum.b[i][0] <== mul.out[i][0];
    }

    // statements
    component sum[n-1];
    for(var i = 0; i < n-1; i++){
        sum[i] = Sum();
    }

    assert(n>=2);
    sum[0].a <== b[0];
    sum[0].b <== b[1];
    for (var i=0; i < n-2; i++) {
        sum[i+1].a <== sum[i].out;
        sum[i+1].b <== b[i+2];
    }

    component cmp = IsEqual();
    cmp.in[0] <== mulSum.out[0][0];
    cmp.in[1] <==sum[n-2].out;

    out <== cmp.out;
}

component main {public [A, b]} = SystemOfEquations(3);