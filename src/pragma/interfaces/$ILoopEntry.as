package pragma.interfaces
{
	import pragma.events.IEventDispatcher;
	import pragma.utils.Loop;

	public interface $ILoopEntry extends IEventDispatcher
	{
		
		// called by Loop when Entry registered
		function notifyRegister($loop:Loop):void;
		
		
		// called by Loop when Entry unregistered
		function notifyUnregister($loop:Loop):void;
		
		
		// called by Loop on every tick, must return true if Entry object is active and do/wait something
		// for example:
		// if socket is connected (wait for data)
		// if SQL connection still not closed
		// if timer is running (wait for time)
		// if keyboard is listening (wait for keypress)
		// if transition happens (may be contain own timer)
		// if file still reading/writing (not closed)
		// etc...
		function heartbeat():Boolean;
	}
}