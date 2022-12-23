if not dirExists("bin"):
  mkdir("bin")
template def(x: string) = switch("define",x)

switch("passC","-march=native -mtune=native")
switch("outDir","bin")
# def("release")