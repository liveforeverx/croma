defmodule Croma.ResultTest do
  use ExUnit.Case
  use ExCheck
  alias Croma.Result, as: R

  def int2result(i) do
    if rem(i, 2) == 0, do: {:ok, i}, else: {:error, i}
  end

  test "Result as Monad" do
    assert R.pure(1) == {:ok, 1}

    assert R.bind({:ok   , 0   }, &int2result/1) == {:ok   , 0   }
    assert R.bind({:ok   , 1   }, &int2result/1) == {:error, 1   }
    assert R.bind({:error, :foo}, &int2result/1) == {:error, :foo}
  end

  test "Result as Functor" do
    assert {:ok   , 1   } |> R.map(&(&1 + 1)) == {:ok   , 2   }
    assert {:error, :foo} |> R.map(&(&1 + 1)) == {:error, :foo}
  end

  test "Result as Applicative" do
    rf = R.pure(fn x -> x + 1 end)
    assert R.ap({:ok   , 1   }, rf) == {:ok   , 2   }
    assert R.ap({:error, :foo}, rf) == {:error, :foo}
  end

  test "Haskell-like do-notation" do
    require R
    r1 = {:ok   , 1   }
    r2 = {:ok   , 2   }
    re = {:error, :foo}

    r = R.m do
    end
    assert r == nil

    r = R.m do
      pure 10
    end
    assert r == {:ok, 10}

    r = R.m do
      a <- r1
      b <- r2
      pure a + b
    end
    assert r == {:ok, 3}

    r = R.m do
      a <- r1
      e <- re
      b <- r2
      pure a + b
    end
    assert r == re
  end

  property :sequence do
    for_all l in list(int) do
      result = Enum.map(l, &int2result/1) |> R.sequence
      if Enum.all?(l, &(rem(&1, 2) == 0)) do
        result == {:ok, l}
      else
        result |> elem(0) == :error
      end
    end
  end

  test "get/1 and get/2" do
    assert R.get({:ok   , 1   }) == 1
    assert R.get({:error, :foo}) == nil

    assert R.get({:ok   , 1   }, 0) == 1
    assert R.get({:error, :foo}, 0) == 0
  end
end