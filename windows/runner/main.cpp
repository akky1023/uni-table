#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Verify native minimum sizing without opening the app or its database.
  if (std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--verify-window-sizing") != command_line_arguments.end()) {
    Win32Window probe;
    if (!probe.Create(L"UniTable sizing check", Win32Window::Point(0, 0),
                      Win32Window::Size(800, 600))) {
      ::CoUninitialize();
      return EXIT_FAILURE;
    }
    MINMAXINFO limits{};
    SendMessage(probe.GetHandle(), WM_GETMINMAXINFO, 0,
                reinterpret_cast<LPARAM>(&limits));
    const UINT dpi = GetDpiForWindow(probe.GetHandle());
    const bool valid = limits.ptMinTrackSize.x >= MulDiv(320, dpi, 96) &&
                       limits.ptMinTrackSize.x <= MulDiv(360, dpi, 96);
    probe.Destroy();
    ::CoUninitialize();
    return valid ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"\u3046\u306b\u6642\u9593\u5272", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
