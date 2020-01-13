//
// Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
//  File:      opt_server_sync.cs
//
//  Purpose :   Demonstrates how to use MOSEK OptServer
//              to solve optimization problem synchronously
using System;
using mosek.fusion;

namespace mosek.fusion.example
{
  public class opt_server_sync
  {
    public static void Main(string[] args)
    {
  
      if (args.Length<2) {
        Console.WriteLine("Missing argument, syntax is:");
        Console.WriteLine("   opt_server_sync host port");
        return;
      }

      String server = args[0];
      String port = args[1];

      // Setup a simple test problem
      Model M = new Model("testOptServer");
      Variable x = M.Variable("x", 3, Domain.GreaterThan(0.0));
      M.Constraint("lc", Expr.Dot(new double[] {1.0, 1.0, 2.0}, x), Domain.EqualsTo(1.0));
      M.Objective("obj", ObjectiveSense.Minimize, Expr.Sum(x));

      // Attach log handler
      M.SetLogHandler(Console.Out);

      // Solve the problem on the OptServer
      M.Solve(server, port);

      // Get the solution
      double[] solx = x.Level();
      Console.WriteLine("x1,x2,x3 = {0}, {1}, {2}", solx[0], solx[1], solx[2]);
    }
  }
}