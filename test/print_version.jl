import Box0
import Box0: version

v = version()

println("Version: ", v)
println(" major: ", v.major)
println(" minor: ", v.minor)
println(" patch: ", v.patch)

first_public_release = VersionNumber(0, 1, 0)
println("first_public_release : ", first_public_release)
println("First Public release: ", v == first_public_release ? "Yes" : "No")

println("Julia VersionNumber conversion: ", VersionNumber(v))
