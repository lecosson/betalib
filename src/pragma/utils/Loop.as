
package pragma.utils
{
	import flash.utils.getTimer;
	
	import C.unistd.sleep;
	
	import pragma.events.Event;
	import pragma.events.EventDispatcher;
	import pragma.events.TimerEvent;
	import pragma.interfaces.$IListener;
	import pragma.interfaces.$ILoopEntry;
	import pragma.namespaces.pragma;
	import pragma.net.Socket;
	
	import shell.Program;
	
	public final class Loop extends EventDispatcher {
		
		private static const TIMEOUT:uint = 3000;
		private static const MINTICKPAUSE:uint = 10;
		private static const MAXTICKPAUSE:uint = 1000;
		
		private var _frequency:uint = 20;
		private var _started:Boolean = false;
		
		internal static var _firstTickAt:uint = getTimer();
		internal static var _lastTickAt:uint = getTimer();
		
		public function get started():Boolean { return _started; }
		public function get frequency():uint { return _frequency; }
		public function set frequency( value:uint ):void {
			value = Math.max(value,MINTICKPAUSE);
			value = Math.min(value,MAXTICKPAUSE);
			_frequency = value;
		}

		
		public function Loop() {
			super();
//			trace('create loop ...');
		}
		
//		public static var timework:int=0;
//		public static var timesleep:int=0;
		public function run():int {
			if (_started) {
				return -1;
			}
			_started = true;
			while (_started) {
				_lastTickAt = getTimer();
				var activities:uint = tick();
				//EventDispatcher.pragma::processDispatchedEvents();
//				timework+=(getTimer()-_lastTickAt);
				if (TIMEOUT>0 && _lastTickAt-_firstTickAt > TIMEOUT) {
					trace("exit by timeout")
					Program.exit(-1);
				}
				if (activities==0) {
					this._started = false;
					this.dispatchEvent(new Event(Event.CLOSE));
					return _lastTickAt-_firstTickAt; // Loop.run() returns time of execution in milliseconds
				} else {
					var t:int = getTimer();
					sleep(_frequency);
//					timesleep+=(getTimer()-t);
				}
			}
			return -1;
		}
		
		private function tick():uint {
			var activities:uint = 0;
			var i:int;
			var entry:$ILoopEntry;
			for (i=_loopEntries.length-1; i>=0; i--) {
				entry = _loopEntries[i];
				if (entry.heartbeat()) {   
					activities++;
				}
				_listenersQueue.sort(function(first:ListenersQueueEntry,second:ListenersQueueEntry):int{ //implement priority
					return first.listener.priority-second.listener.priority;
				});
				while (_listenersQueue.length>0) {
					var lq:* = _listenersQueue.pop();
					var lqentry:ListenersQueueEntry = lq as ListenersQueueEntry;
					//lqentry.listener.dispatcher.pragma::applyEvent(lqentry.listener, lqentry.event);
					(lqentry.listener.dispatcher as EventDispatcher).pragma::applyEvent(lqentry.listener, lqentry.event);
				}
			}
			return activities;
		}
		
		private var _loopEntries:Vector.<$ILoopEntry> = new Vector.<$ILoopEntry>();
		pragma function addEntry($entry:$ILoopEntry):void {
			_loopEntries.push($entry);
			$entry.notifyRegister(this); //notify entry to subscribe, prepare, etc.
		}
		pragma function removeEntry($entry:$ILoopEntry):void {
			var pos:int = _loopEntries.indexOf($entry);
			if (pos>=0) {
				$entry.notifyUnregister(this); //notify entry to unsubscribe listeners, dispose resources, etc.
				_loopEntries.splice(pos,1);
			}
		}
		
		private var _listenersQueue:Vector.<ListenersQueueEntry> = new Vector.<ListenersQueueEntry>();
		pragma function applyListenersQueue($listener:$IListener, $event:Event):void {
			var lqentry:ListenersQueueEntry = new ListenersQueueEntry($listener,$event);
			_listenersQueue.push(lqentry);
		}
	}
	
	internal class ListenersQueueEntry {
	
		import pragma.events.Event;
	
		public var listener:$IListener;
		public var event:Event;
		
		public function ListenersQueueEntry($listener:$IListener, $event:Event) {
			super();
			listener = $listener;
			event = $event;
		}
		
		public function toString():String {
			return "[ListenersQueueEntry:"+event.type+"]"; 
		}
	}
}
