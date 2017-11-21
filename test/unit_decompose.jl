# ==============================
# Check that Issue #43 is fixed
# ==============================
Ω0 = LazySets.ConvexHull{LazySets.CartesianProductArray{LazySets.BallInf},LazySets.LinearMap{LazySets.CartesianProductArray{LazySets.BallInf}}}(LazySets.CartesianProductArray{LazySets.BallInf}(LazySets.BallInf[LazySets.BallInf([0.767292, 0.936613], 0.1), LazySets.BallInf([0.734104, 0.87296], 0.1)]), LazySets.LinearMap{LazySets.CartesianProductArray{LazySets.BallInf}}([1.92664 1.00674 1.0731 -0.995149; -2.05704 3.48059 0.0317863 1.83481; 0.990993 -1.97754 0.754192 -0.807085; -2.43723 0.782825 -3.99255 3.93324], LazySets.CartesianProductArray{LazySets.BallInf}(LazySets.BallInf[LazySets.BallInf([0.767292, 0.936613], 0.1), LazySets.BallInf([0.734104, 0.87296], 0.1)])))

dec = Approximations.decompose(Ω0)
dec1 = dec.sfarray[1]

@test dec1.constraints_list[1].b ≈ 2.84042586
@test dec1.constraints_list[2].b ≈ 4.04708832
@test dec1.constraints_list[3].b ≈ -0.667292
@test dec1.constraints_list[4].b ≈ -0.836613
