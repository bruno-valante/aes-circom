pragma circom  2.0.0;

include "./key_expansion.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/gates.circom";

template AddRoundKey(nk){
    signal input state[nk][4];
    signal input roundKey[nk*4];
    signal output newState[nk][4];

    component xorbyte[nk][4];

    for (var i = 0; i < nk; i++) {
        for (var j = 0; j < 4; j++) {
            xorbyte[i][j] = XorByte();
            xorbyte[i][j].a <== state[i][j];
            xorbyte[i][j].b <== roundKey[4*i+j];
            newState[i][j] <== xorbyte[i][j].out;
        }
    }
}

template SubBlock(nk){
        signal input state[nk][4];
        signal output newState[nk][4];
        component sbox[nk];

        for (var i = 0; i < 4; i++) {
                sbox[i] = SubstituteWord();
                sbox[i].bytes <== state[i];
                newState[i] <== sbox[i].substituted;
        }
}

template ShiftRows(nk){
    signal input state[4][nk];
    signal output newState[4][nk];
    var shiftRows[3][4] = [
        [0, 1, 2, 3], 
        [0, 1, 2, 3],
        [0, 1, 3, 4]
    ];

    component shiftWord[4];

    for (var i = 0; i < 4; i++) {
        shiftWord[i] = Rotate(shiftRows[(nk \ 2) - 2][i], nk);
        shiftWord[i].bytes <== state[i];
        newState[i] <== shiftWord[i].rotated;
    }
}

template MixColumns(nk){
    signal input state[4][nk];
    signal output out[4][nk];

    component s0[nk];
    component s1[nk];
    component s2[nk];
    component s3[nk];

    for (var i = 0; i < nk; i++) {
        s0[i] = S0();
        s1[i] = S1();
        s2[i] = S2();
        s3[i] = S3();

        for(var j = 0; j < 4; j++) {
            s0[i].in[j] <== state[j][i];
            s1[i].in[j] <== state[j][i];
            s2[i].in[j] <== state[j][i];
            s3[i].in[j] <== state[j][i];
        }

        out[0][i] <== s0[i].out;
        out[1][i] <== s1[i].out;
        out[2][i] <== s2[i].out;
        out[3][i] <== s3[i].out;
    }
}

//can make these generic but computation increases when multiplying by 1 (even though it won't be necessary)
template S0(){
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 0; i < 4; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    component mul = XTimes(2);
    mul.in <== num2bits[0].out;

    component mul2 = XTimes(3);
    mul2.in <== num2bits[1].out;

    xor[0] = XorBits();
    xor[0].a <== mul.out;
    xor[0].b <== mul2.out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== num2bits[3].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

template S1(){
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 0; i < 4; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    component mul = XTimes(2);
    mul.in <== num2bits[1].out;

    component mul2 = XTimes(3);
    mul2.in <== num2bits[2].out;

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== mul.out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== mul2.out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== num2bits[3].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

template S2() { 
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 0; i < 4; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    xor[0] = XorBits();
    xor[0].a <== num2bits[0].out;
    xor[0].b <== num2bits[1].out;

    component mul2 = XTimes2();
    mul2.in <== num2bits[2].out;

    component mul = XTimes(3);
    mul.in <== num2bits[3].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== mul2.out;

    xor[2] = XorBits();
    xor[2].a <== xor[1].out;
    xor[2].b <== mul.out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

template S3() {
    signal input in[4];
    signal output out;
    component num2bits[4];
    component xor[3];

    for (var i = 0; i < 4; i++) {
        num2bits[i] = Num2Bits(8);
        num2bits[i].in <== in[i];
    }

    component mul3 = XTimes(3);
    mul3.in <== num2bits[0].out;

    xor[0] = XorBits();
    xor[0].a <== mul3.out;
    xor[0].b <== num2bits[1].out;

    xor[1] = XorBits();
    xor[1].a <== xor[0].out;
    xor[1].b <== num2bits[2].out;

    component mul2 = XTimes2();
    mul2.in <== num2bits[3].out;

    xor[2] = XorBits();
    xor[2].a <== mul2.out;
    xor[2].b <== xor[1].out;

    component b2n = Bits2Num(8);
    for (var i = 0; i < 8; i++) {
        b2n.in[i] <== xor[2].out[i];
    }

    out <== b2n.out;
}

template XTimes2(){
    signal input in[8];
    signal output out[8];

    component xtimeConstant = Num2Bits(8);
    xtimeConstant.in <== 0x1b;

    component xor[7];

    component isZero = IsZero();
    isZero.in <== in[7];

    out[0] <== 1-isZero.out;
    for (var i = 0; i < 7; i++) {
        xor[i] = XOR();
        xor[i].a <== in[i];
        xor[i].b <== xtimeConstant.out[i+1] * (1-isZero.out);
        out[i+1] <== xor[i].out;
    }
}

template XorByte(){
        signal input a;
        signal input b;
        signal output out;

        component abits = Num2Bits(8);
        abits.in <== a;

        component bbits = Num2Bits(8);
        bbits.in <== b;

        component XorBits = XorBits();
        XorBits.a <== abits.out;
        XorBits.b <== bbits.out;

        component num = Bits2Num(8);
        num.in <== XorBits.out;

        out <== num.out;
}

template XorBits(){
        signal input a[8];
        signal input b[8];
        signal output out[8];

    component xor[8];
    for (var i = 0; i < 8; i++) {
        xor[i] = XOR();
        xor[i].a <== a[i];
        xor[i].b <== b[i];
        out[i] <== xor[i].out;
    }
}

template XTimes(n){
    signal input in[8];
    signal output out[8];

    component bits = Num2Bits(8);
    bits.in <== n;

    component XTimes2[7];

    XTimes2[0] = XTimes2();
    XTimes2[0].in <== in;

    for (var i = 1; i < 7; i++) {
            XTimes2[i] = XTimes2();
            XTimes2[i].in <== XTimes2[i-1].out;
    }

    component xor[8];
    component mul[8];
    signal inter[8][8];

    mul[0] = MulByte();
    mul[0].a <== bits.out[0];
    mul[0].b <== in;
    inter[0] <== mul[0].c;

    for (var i = 1; i < 8; i++) {
        mul[i] = MulByte();
        mul[i].a <== bits.out[i];
        mul[i].b <== XTimes2[i-1].out;

                xor[i] = XorBits();
                xor[i].a <== inter[i-1];
                xor[i].b <== mul[i].c;
                inter[i] <== xor[i].out;
        }

    out <== inter[7];
}

template MulByte(){
    signal input a;
    signal input b[8];
    signal output c[8];

    for (var i = 0; i < 8; i++) {
        c[i] <== a * b[i];
    }
}
       
// template Cipher(nk){
//         assert(nk == 4 || nk == 6 || nk == 8 );
//         signal input block[nk][4];
//         signal input cipher[nk][nk];

//         var nr = Rounds(nk);

//         signal input key[nk * 4];

//         component keyExpansion = KeyExpansion(nk);
//         keyExpanded.key <== key;

//         component addRoundKey[nr+1];
//         component subBytes[nr];

//         signal interBlock[nr][nk][4];


//         addRoundKey[0] = AddRoundKey(nk);
//         addRoundKey[0].state <== block;
//         for (var i = 0; i < nk; i++) {
//                 for (var j = 0; j < 4; j++) {
//                         addRoundKey[0].roundKey[4*i+j] <== keyExpanded.keyExpanded[i][j];
//                 }
//         }
//         interBlock[0] <== addRoundKey[0].out;
//         for (var i = 1; i < nr; i++) {
//                 subBytes[i-1] = SubBlock(nk);
//                 subBytes[i-1].state <== interBlock[i-1];

//                 shiftRows[i-1] = ShiftRows(nk);
//                 shiftRows[i-1].state <== subBytes[i-1].newState;

//                 mixColumns[i-1] = MixColumns(nk);
//                 mixColumns[i-1].state <== shiftRows[i-1].newState;

//                 addRoundKey[i] = AddRoundKey(nk);
//                 addRoundKey[i].state <== mixColumns[i-1].newState;
//                 for (var j = 0; j < nk; j++) {
//                         for (var k = 0; k < 4; k++) {
//                                 addRoundKey[i].roundKey[4*j+k] <== keyExpanded.keyExpanded[4*i+j][k];
//                         }
//                 }

//                 interBlock[i] <== addRoundKey[i].out;
//         }

//         subBytes[nr-1] = SubBlock(nk);
//         subBytes[nr-1].state <== interBlock[nr-1];

//         shiftRows[nr-1] = ShiftRows(nk);
//         shiftRows[nr-1].state <== subBytes[nr-1].newState;

//         addRoundKey[nr] = AddRoundKey(nk);
//         addRoundKey[nr].state <== shiftRows[nr-1].newState;
//         for (var i = 0; i < nk; i++) {
//                 for (var j = 0; j < 4; j++) {
//                         addRoundKey[nr].roundKey[4*i+j] <== keyExpanded.keyExpanded[4*nr+i][j];
//                 }
//         }

//         cipher <== addRoundKey[nr].out;
// }