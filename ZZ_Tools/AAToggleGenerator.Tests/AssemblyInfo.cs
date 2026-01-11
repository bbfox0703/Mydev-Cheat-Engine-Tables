using Microsoft.VisualStudio.TestTools.UnitTesting;

// Enable test parallelization for better performance
[assembly: Parallelize(Workers = 0, Scope = ExecutionScope.MethodLevel)]
