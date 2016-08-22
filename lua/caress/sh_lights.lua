caress.lightFlags = {}
local lightFlags = caress.lightFlags

lightFlags.Head = 1
lightFlags.BrakePassive = bit.lshift(lightFlags.Head, 1)
lightFlags.Brake = bit.lshift(lightFlags.BrakePassive, 1)
lightFlags.Reverse = bit.lshift(lightFlags.Brake, 1)
lightFlags.LBlinkers = bit.lshift(lightFlags.Reverse, 1)
lightFlags.RBlinkers = bit.lshift(lightFlags.LBlinkers, 1)
lightFlags.Emergency1 = bit.lshift(lightFlags.RBlinkers, 1)
lightFlags.Emergency2 = bit.lshift(lightFlags.Emergency1, 1)
lightFlags.Emergency3 = bit.lshift(lightFlags.Emergency2, 1)
