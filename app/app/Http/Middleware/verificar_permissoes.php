<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Auth;

class verificar_permissoes
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle($request, Closure $next,...$permissoesNecessarias)
    {
        if(Auth::user()->temTipos($permissoesNecessarias)){
            return $next($request);
        }

        abort(403,"sem permissões");
    }
}
