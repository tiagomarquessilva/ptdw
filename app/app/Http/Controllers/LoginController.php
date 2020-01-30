<?php

namespace App\Http\Controllers;

use App\Utilizador;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use \Illuminate\Validation\Validator;
use Illuminate\Support\Facades\Validator as Validator1;
use stdClass;

class LoginController extends Controller
{
    public function index()
    {
        return view("pages.login");
    }

    public function login(Request $request)
    {

        //$credenciais = $request->only("email","password");
        $credenciais = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);
        $credenciais['ativo'] = true;
        
        if (Auth::attempt($credenciais)) {
            return redirect("/");
        }

        return redirect()->back()->withInput($credenciais)->withErrors(["login_error" => "Credenciais incorretas"]);
        //retornar erro!
        //return "failed";
    }


    public function logout()
    {
        Auth::logout();
        return redirect("/login");
    }

    public function update_user_info(Request $request)
    {
        // validar entradas
        $validator = Validator1::make($request->all(), [
            'edit_user_name' => 'string|max:255',
            'edit_user_contact' => 'integer|between:900000000,999999999',
            'edit_user_email' => 'email|max:255'
        ]);

        // erro se validação falha, se nao guarda unidade de saude
        if ($validator->fails()) {
            return json_encode([
                "success" => false,
                "insertion_error" => false,
                "validation_errors" => $validator->errors()
            ]);
        } else {
            $user = Utilizador::find(Auth::id());
            $user->nome = $request->edit_user_name;
            $user->contacto = $request->edit_user_contact;
            $user->email = $request->edit_user_email;
            $user->password = bcrypt($request->edit_user_password);

            if ($user->save()) {
                redirect('/user_profile')->with('user_updated', true);
                return json_encode([
                    "success" => true,
                    "insertion_error" => false,
                    "validation_errors" => new stdClass()
                ]);
            } else {
                return json_encode([
                    "success" => false,
                    "insertion_error" => true,
                    "validation_errors" => new stdClass()
                ]);
            }
        }
    }
}
