defmodule LookupPhoenix.Token do

    import Joken

    def get(user_id) do
      my_token = %{"user_id" => user_id}
      |> token
      |> with_validation("user_id", &(&1 == user_id))
      |> with_signer(hs256("yada82043mU,@izq0#$mcq^&!HFQpnp8i-nc"))
      |> sign
      |> get_compact
    end

    def validate(token, user_id) do
      token
      |> token
      |> with_validation("user_id", &(&1 == user_id))
      |> with_signer(hs256("yada82043mU,@izq0#$mcq^&!HFQpnp8i-nc"))
      |> verify
    end

    def authenticated(token, user_id) do
      result = LookupPhoenix.Token.validate(token, user_id)
      result.error == nil
    end

end