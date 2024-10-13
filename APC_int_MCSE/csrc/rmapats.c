// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarIsDeposited=0;
scalar fNettypeIsForced=0;
scalar fNettypeIsReleased=0;
void  hsG_0__0 (struct dummyq_struct * I1393, EBLK  * I1388, U  I619);
void  hs_0_M_291_0__simv_daidir (UB  * pcode, scalar  val)
{
    UB  * I1725;
    val = (scalar )(((RP )pcode) & 3);
    pcode = (UB  *)((RP )pcode & ~3);
    if (*(pcode + 0) == val) {
        return  ;
    }
    *(pcode + 0) = val;
    {
        {
            RP  I1582;
            RP  * I656 = (RP  *)(pcode + 4);
            {
                I1582 = *I656;
                if (I1582) {
                    hsimDispatchCbkMemOptNoDynElabS(I656, val, 0U);
                }
            }
        }
    }
    pcode += 8;
    UB  * I740 = *(UB  **)(pcode + 0);
    if (I740 != (UB  *)(pcode + 0)) {
        RmaSwitchGate  * I1751 = (RmaSwitchGate  *)I740;
        RmaSwitchGate  * I948 = 0;
        do {
            RmaIbfPcode  * I1083 = (RmaIbfPcode  *)(((UB  *)I1751) + 12U);
            ((FP )(I1083->I1083))((void *)I1083->pcode, val);
            RmaDoublyLinkedListElem  I1752;
            I1752.I948 = 0;
            RmaSwitchGateInCbkListInfo  I1753;
            I1753.I1239 = 0;
            I948 = (RmaSwitchGate  *)I1751->I634.I1754.I948;
        } while ((UB  *)(I1751 = I948) != (UB  *)I740);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
