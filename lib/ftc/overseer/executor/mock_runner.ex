defmodule FTC.Overseer.Executor.MockRunner do
  @moduledoc false
  #
  # Provides a fake shell executor for use in development and testing.
  #

  @doc """
  Provide fake output for common shell commands. Returns an error for unimplemented commands.
  """
  @spec run(String.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, String.t(), pos_integer}
  def run(command, opts \\ [])

  def run("iwconfig 2>/dev/null" <> _, _opts), do: {:ok, "wlan0\nwlan0\nwlan1\nwlan2"}

  def run("iwconfig wlan" <> <<num::bytes-size(1)>> <> _, _opts) do
    {:ok,
     """
     wlan#{num}     IEEE 802.11  ESSID:off/any
               Mode:Managed  Access Point: Not-Associated   Tx-Power=0 dBm
               Retry short  long limit:2   RTS thr:off   Fragment thr:off
               Encryption key:off
               Power Management:off
     """}
  end

  def run("./bin/scan" <> _, _opts) do
    """
    00:00:00:00:00:01 | 1 | -40 | "DIRECT-AA-1-RC"
    00:00:00:00:00:02 | 6 | -40 | "DIRECT-BB-2-RC"
    00:00:00:00:00:03 | 11 | -40 | "DIRECT-CC-3-RC"
    00:00:00:00:00:04 | 157 | -40 | "DIRECT-DD-4-RC"
    00:00:00:00:00:05 | 1 | -40 | "DIRECT-EE-5-RC"
    00:00:00:00:00:06 | 6 | -40 | "DIRECT-FF-6-RC"
    00:00:00:00:00:07 | 11 | -40 | "DIRECT-GG-7-RC"
    00:00:00:00:00:08 | 157 | -40 | "DIRECT-HH-8-RC"
    00:00:00:00:00:09 | 1 | -80 | "DIRECT-AA-1-B-RC"
    """
  end

  def run(_command, _opts), do: {:error, "Not implemented", 1}
end
