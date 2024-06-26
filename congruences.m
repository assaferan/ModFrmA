freeze;
 
/****-*-magma-* EXPORT DATE: 2004-03-08 ************************************
                                                                            
                     MODFORM: Modular Forms in MAGMA
 
                              William A. Stein        
                         
   FILE: congruences.m

   11/10/02: Added some support for congruence for sequences of spaces.

   $Header: /home/was/magma/packages/ModFrm/code/RCS/congruences.m,v 1.13 2002/10/26 22:40:39 was Exp was $

   $Log: congruences.m,v $
   Revision 1.13  2002/10/26 22:40:39  was
   More fine tuning.

   Revision 1.12  2002/10/26 22:35:46  was
   nothing.

   Revision 1.11  2002/10/26 22:35:24  was
   More fine tuning.

   Revision 1.10  2002/10/26 22:21:42  was
   Finished fixing bug...

   Revision 1.9  2002/10/26 22:21:03  was
   Fixed a bug in CongruenceGroupAnemic -- sometimes there were false congruences
   because one of the individual spaces wasn't saturated.

   Revision 1.8  2002/05/30 10:00:27  was
   Added CongruenceGroup for newforms.

   Revision 1.7  2002/05/28 08:36:07  was
   ...

   Revision 1.6  2002/05/28 08:35:34  was
   Removed version of CongruenceGroupAnemic that doesn't ask for precision, because I don't know how
   to compute the correct precision.  Definitely what is given there currently is wrong.  E.g.,
   Level 2, weight 8, congruence between cuspidal and Eisenstein stuff.

   Revision 1.5  2002/05/06 05:27:31  was
   Allow congruence groups even when not over Z or Q, since basis is, by definition, always
   actually defined over Z!

   Revision 1.4  2002/04/13 07:26:33  was
   ??

   Revision 1.3  2001/08/27 23:33:14  was
   Added CongruenceGroupAnemic.

   Revision 1.2  2001/05/30 18:54:09  was
   Created.

   Revision 1.1  2001/05/16 03:50:53  was
   Initial revision

      
 ***************************************************************************/

import "misc.m" : SaturatePowerSeriesSequence;

function DepriveAndSaturate(B, N, prec)
   R<q> := Parent(B[1]);
   inds := [j : j in [0..prec-1] | GCD(j,N) eq 1];
   C := [&+[Coefficient(f,i)*q^i : i in inds] + O(q^prec) : f in B];
   return SaturatePowerSeriesSequence(C);
end function;


function IndexInSaturation(B, prec, N)
   assert Type(B) eq SeqEnum;
   // Returns the index and structure of the Z-module generated by the sum of
   // the saturations of B1 and B2, taking into account only coefficients
   // of the q-expansion of index coprime to N.  We only saturate B1 and B2
   // when N=/=1, since otherwise they should already be saturated.
   // When N=/=1, they might not be, e.g., "23k2A" and "46k2A".
   if #B le 1 or (#B eq 2 and (#B[1] eq 0 or #B[2] eq 0)) then 
      return AbelianGroup([1]);
   end if;
   if N eq 1 then
      P := &cat B;
   else
      P := &cat [DepriveAndSaturate(A,N, prec) : A in B];
   end if;
   R    := Parent(P[1]);
   inds := [j : j in [0..prec-1] | GCD(j,N) eq 1];
   X    := [[Coefficient(f,i) : i in inds] : f in P];
   D    := RMatrixSpace(Integers(),#P,#inds)!(&cat X);
   S    := SmithForm(D);
   if Rank(S) lt Nrows(S) then
      return AbelianGroup([0]);  // any congruence you'd like!
   end if;

   return AbelianGroup([S[i,i] : i in [1..Min(Nrows(S),Ncols(S))] | S[i,i] gt 1 ]);
end function;

intrinsic CongruenceGroup(M1::ModFrmA, M2::ModFrmA) -> GrpAb
{A group that measures all congruences (to precision prec)
between some integral modular form in M1 and some modular form in M2.}
   require Characteristic(BaseRing(M1)) eq 0 and Characteristic(BaseRing(M2)) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";
   return CongruenceGroup(M1, M2, 
         1 + Max(PrecisionBound(M1 : Exact := false), PrecisionBound(M2 : Exact := false)));
end intrinsic;

intrinsic CongruenceGroup(M1::ModFrmA, M2::ModFrmA, prec::RngIntElt) -> GrpAb
{"} // "
   require Characteristic(BaseRing(M1)) eq 0 and Characteristic(BaseRing(M2)) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";
   R := PowerSeriesRing(PolynomialRing(IntegerRing()));
   return IndexInSaturation([[R| PowerSeries(f,prec) : f in Basis(M1)],
                            [R| PowerSeries(f,prec) : f in Basis(M2)]],  prec, 1);
end intrinsic;

intrinsic CongruenceGroupAnemic(M1::ModFrmA, M2::ModFrmA, prec::RngIntElt) -> GrpAb
{A group that measures all possible congruences to precision prec
between some integral modular form in M1 and some modular form in M2, where
we only consider coefficients of q^n when n is 0 or coprime to the levels
of M1 and M2.}
   require Characteristic(BaseRing(M1)) eq 0 and Characteristic(BaseRing(M2)) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";

   R := PowerSeriesRing(PolynomialRing(IntegerRing()));
   B1 := [R|PowerSeries(f,prec) : f in Basis(M1)];
   B2 := [R|PowerSeries(f,prec) : f in Basis(M2)];
   return IndexInSaturation([B1, B2],  prec, Level(M1)*Level(M2));
end intrinsic;

intrinsic CongruenceGroup(M1::ModSym, M2::ModSym, prec::RngIntElt) -> GrpAb
{A group that measures all possible congruences (to precision prec)
between some integral modular form in M1 and some modular form in M2.
The given space(s) of modular symbols must be cuspidal.}
   require Type(BaseField(M1)) eq FldRat : 
             "The base field of argument 1 must be Q.";
   require Type(BaseField(M2)) eq FldRat : 
             "The base field of argument 2 must be Q.";
   require IsCuspidal(M1) : "Argument 1 must be cuspidal.";
   require IsCuspidal(M2) : "Argument 2 must be cuspidal.";
   return IndexInSaturation([qIntegralBasis(M1,prec), qIntegralBasis(M2,prec)], prec, 1);
end intrinsic;

intrinsic CongruenceGroup(M1::ModSymA, M2::ModFrmA, prec::RngIntElt) -> GrpAb
{"} // "
   require Type(BaseField(M1)) eq FldRat : 
             "The base field of argument 1 must be Q.";
   require Characteristic(BaseRing(M2)) eq 0 : 
             "The base ring of argument 1 must have characteristic 0.";
   R := PowerSeriesRing(PolynomialRing(IntegerRing()));
   return IndexInSaturation([qIntegralBasis(M1,prec), 
                            [R| PowerSeries(f,prec) : f in Basis(M2)]], 
                            prec, 1);
end intrinsic;

intrinsic CongruenceGroup(M1::ModFrmA, M2::ModSymA, prec::RngIntElt) -> GrpAb
{Same as CongruenceGroup(M2,M1,prec)}
   require Characteristic(BaseRing(M1)) eq 0 : 
             "The base ring of argument 1 must have characteristic 0.";
   require Type(BaseField(M2)) eq FldRat : 
             "The base field of argument 2 must be Q.";
   return CongruenceGroup(M2,M1,prec);
end intrinsic;

intrinsic CongruenceGroup(M::[ModSym], prec::RngIntElt) -> GrpAb
{A group that measures all possible congruences to precision prec 
between some integral modular form in some Mi and some Mj where Mi, Mj in M.
The given spaces must be cuspidal.}
   for A in M do 
      require Type(BaseField(A)) eq FldRat : 
             "Base fields of argument 1 must be Q.";
      require IsCuspidal(A) : "Argument 1 must be cuspidal.";
   end for;
   return IndexInSaturation([qIntegralBasis(A,prec) : A in M], prec, 1);
end intrinsic;


intrinsic CongruenceGroupAnemic(M1::ModSym, M2::ModSym, prec::RngIntElt) -> GrpAb
{A group that measures all possible congruences to precision prec
between some integral modular form in M1 and some modular form in M2, but
where only the coefficients a_n, with n coprime to both levels, are considered.
The given space(s) of modular symbols must be cuspidal.}
   require Type(BaseField(M1)) eq FldRat : 
             "The base field of argument 1 must be Q.";
   require Type(BaseField(M2)) eq FldRat : 
             "The base field of argument 2 must be Q.";
   require IsCuspidal(M1) : "Argument 1 must be cuspidal.";
   require IsCuspidal(M2) : "Argument 2 must be cuspidal.";
   return IndexInSaturation([qIntegralBasis(M1,prec), qIntegralBasis(M2,prec)], prec, 
                  Level(M1)*Level(M2));
end intrinsic;

intrinsic CongruenceGroupAnemic(M1::ModSymA, M2::ModFrmA, prec::RngIntElt) -> GrpAb
{"} // "
   require Type(BaseField(M1)) eq FldRat : 
             "The base field of argument 1 must be Q.";
   require Characteristic(BaseRing(M2)) eq 0 : 
             "The base ring of argument 1 must have characteristic 0.";
   require IsCuspidal(M1) : "Argument 1 must be cuspidal.";
   R := PowerSeriesRing(PolynomialRing(IntegerRing()));
   return IndexInSaturation([qIntegralBasis(M1,prec), 
                            [R| PowerSeries(f,prec) : f in Basis(M2)]], 
			    prec, Level(M1)*Level(M2));
end intrinsic;

intrinsic CongruenceGroupAnemic(M1::ModFrmA, M2::ModSymA, prec::RngIntElt) -> GrpAb
{Same as CongruenceGroupAnemic(M2,M1,prec)}
   require Characteristic(BaseRing(M1)) eq 0 : 
             "The base ring of argument 1 must have characteristic 0.";
   require Type(BaseField(M2)) eq FldRat : 
             "The base field of argument 2 must be Q.";
   require IsCuspidal(M1) : "Argument 1 must be cuspidal.";
   return CongruenceGroupAnemic(M2,M1,prec);
end intrinsic;


///////////////////////////////////////////

intrinsic CongruenceGroup(f1::ModFrmAElt, f2::ModFrmAElt) -> GrpAb
{For newforms f1 and f2, returns the CongruenceGroup of the corresponding newform spaces.}
   require Characteristic(BaseRing(Parent(f1))) eq 0 and Characteristic(BaseRing(Parent(f2))) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";
   require IsNewform(f1) and IsNewform(f2) : "Arguments 1 and 2 must be newforms";
   return CongruenceGroup(Parent(f1),Parent(f2));
end intrinsic;

intrinsic CongruenceGroup(f1::ModFrmAElt, f2::ModFrmAElt, prec::RngIntElt) -> GrpAb
{"} // "
   require Characteristic(BaseRing(Parent(f1))) eq 0 and Characteristic(BaseRing(Parent(f2))) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";
   require IsNewform(f1) and IsNewform(f2) : "Arguments 1 and 2 must be newforms";
   return CongruenceGroup(Parent(f1),Parent(f2),prec);
end intrinsic;

intrinsic CongruenceGroupAnemic(f1::ModFrmAElt, f2::ModFrmAElt, prec::RngIntElt) -> GrpAb
{For newforms f1 and f2, returns CongruenceGroupAnemic of the corresponding newform spaces.}
   require Characteristic(BaseRing(Parent(f1))) eq 0 and Characteristic(BaseRing(Parent(f2))) eq 0 : 
         "Arguments 1 and 2 must have characteristic 0.";
   require IsNewform(f1) and IsNewform(f2) : "Arguments 1 and 2 must be newforms";
   return CongruenceGroupAnemic(Parent(f1),Parent(f2),prec);
end intrinsic;

