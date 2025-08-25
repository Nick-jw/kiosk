import { useState, useEffect } from "preact/hooks";
import { Dialog, DialogPanel, DialogTitle, Transition, TransitionChild, } from "@headlessui/react";

export function App() {
  const [touchCount, setTouchCount] = useState(0);
  const [lastTouchTime, setLastTouchTime] = useState<Date | null>(null);

  const [currentTime, setCurrentTime] = useState(new Date());

  const [showDialog, setShowDialog] = useState(false);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const handleTouchTest = () => {
    setTouchCount((prev) => prev + 1);
    setLastTouchTime(new Date());

    setShowDialog(true);
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 text-white flex flex-col">
      <header className="p-6 text-center bg-black/20 backdrop-blur-sm">
        <h1 className="text-3xl font-bold mb-2">Raspberry Pi Kiosk</h1>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center p-6 space-y-8">
        <div className="text-center">
          <div className="text-4xl font-mono font-bold mb-2 drop-shadow-lg">
            {currentTime.toLocaleTimeString()}
          </div>
        </div>

        <div className="text-center space-y-4">
          <button onClick={handleTouchTest} className="bg-white/20 hover:bg-white/30 active:bg-white/40 active:scale-95 border-2 border-white/50 
                                                        hover:border-white/70 px-8 py-4 rounded-xl text-xl font-semibold transition-all duration-200 ease-out
                                                        min-h-[44px] min-w-[200px] shadow-lg hover:shadow-xl">
                                                          Touch Test
            </button>

            <div className="space-y-2 text-center">
              <div className="text-lg font-semibold">Touches: <span className="text-yellow-400">{touchCount}</span></div>
              {lastTouchTime && (
                <div className="text-sm opacity-80">Last Touch: {lastTouchTime.toLocaleTimeString()}</div>
              )}
            </div>
        </div>
      </main>

      <footer className="p-4 text-center bg-black/20 backdrop-blur-sm">
        <div className="text-sm opacity-80">{currentTime.toLocaleDateString()}</div>
      </footer>

      <Transition show={showDialog}>
      <Dialog onClose={() => setShowDialog(false)} className="relative z-50">
        <TransitionChild enter="ease-out duration-300" enterFrom="opacity-0" enterTo="opacity-100" leave="ease-in duration-200" leaveFrom="opacity-100" leaveTo="opacity-0">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
        </TransitionChild>

        <div className="fixed inset-0 flex items-center justify-center p-4">
          <TransitionChild enter="ease-out duration-300" enterFrom="opacity-0 scale-95 translate-y-0" enterTo="opacity-100 scale-100 translate-y-0"
                            leave="ease-in duration-200" leaveFrom="opacity-100 scale-100 translate-y-0" leaveTo="opacity-0 scale-95 translate-y-0">        
          <DialogPanel className="bg-white text-gray-900 p-8 rounded-2xl shadow-2xl max-w-md w-full space-y-4">
            <DialogTitle className="text-2xl font-bold text-center">Touch Registered</DialogTitle>

            <div className="text-center space-y-2">
              <p className="text-lg">Touch {touchCount} detected</p>
              {lastTouchTime && (
                <p className="text-sm text-gray-600">at {lastTouchTime.toLocaleTimeString()}</p>
              )}
            </div>

            <div className="flex justify-center">
              <button onClick={() => setShowDialog(false)} className="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-3 rounded-lg font-semibold transition-colors duration-200 min-h-[44px]">
                OK
              </button>
            </div>
          </DialogPanel>
          </TransitionChild>
        </div>
      </Dialog>
      </Transition>
    </div>
  )
}