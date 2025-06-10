<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/example', function () {
    return view('frontend');
});

# spaからバックエンドにアクセスするためのAPI
Route::prefix('resources')
    ->as('resources.')
    ->group(function () {
        Route::post('login', function (Request $request) {
            $request->validate([
                'email' => 'required|email',
                'password' => 'required|min:6',
            ]);
            Auth::attempt(request()->only('email', 'password'));
            if (Auth::check()) {
                return response()->json(['message' => 'Login successful']);
            } else {
                return response()->json(['message' => 'Invalid credentials'], 401);
            }
        })->name('login');
        Route::post('logout', function () {
            Auth::logout();
            return response()->json(['message' => 'Logout successful']);
        })->name('logout');
        Route::get('me', function () {
            if (Auth::check()) {
                return response()->json(['user' => Auth::user()]);
            } else {
                return response()->json(['message' => 'Unauthorized'], 401);
            }
        })->name('me');
        Route::prefix('users')
            ->as('users.')
            ->group(function () {
                Route::get('', function () {
                    return response()->json(['users' => \App\Models\User::all()]);
                })->name('list');
                Route::get('{id}', function ($id) {
                    $user = \App\Models\User::find($id);
                    if ($user) {
                        return response()->json(['user' => $user]);
                    } else {
                        return response()->json(['message' => 'User not found'], 404);
                    }
                })->name('get');
                Route::post('', function (Request $request) {
                    $request->validate([
                        'name' => 'required|string|max:255',
                        'email' => 'required|email|unique:users,email',
                        'password' => 'required|string|min:6',
                    ]);
                    $user = \App\Models\User::create($request->only('name', 'email', 'password'));
                    return response()->json(['user' => $user], 201);
                })->name('create');
                Route::put('{id}', function (Request $request, $id) {
                    $user = \App\Models\User::find($id);
                    if ($user) {
                        $request->validate([
                            'name' => 'sometimes|required|string|max:255',
                            'email' => 'sometimes|required|email|unique:users,email,' . $id,
                            'password' => 'sometimes|required|string|min:6',
                        ]);
                        $user->update($request->only('name', 'email', 'password'));
                        return response()->json(['user' => $user]);
                    } else {
                        return response()->json(['message' => 'User not found'], 404);
                    }
                })->name('update');
                Route::delete('{id}', function ($id) {
                    $user = \App\Models\User::find($id);
                    if ($user) {
                        $user->delete();
                        return response()->json(['message' => 'User deleted']);
                    } else {
                        return response()->json(['message' => 'User not found'], 404);
                    }
                })->name('delete')->middleware('auth');
            });
    });