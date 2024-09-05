<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class ApiAuthController extends Controller
{
    public function register(Request $request){
        $data = $request->validate([
          'name'=> 'required|max:255',
          'email'=> 'required|email|unique:users',
          'password' => 'required'
        ]);
      $user =  User::create($data);
      $token = $user->createToken($request->name);
      return [
          'user' => $user,
          'token' => $token->plainTextToken
      ];
      }

      public function login(Request $request){
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

          $user = User::where('email', $request->email) -> first();

          if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'The provided credentials are incorrect.'
            ], 401);
          }
          $token = $user->createToken($user->name);
          return [
              'user' => $user,
              'token' => $token->plainTextToken
          ];

    }

    public function logout(Request $request){
        $request->user()->tokens()->delete();
         return ['message' => 'User logged out successfully'];
    }


}
