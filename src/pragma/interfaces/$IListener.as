package pragma.interfaces
{
	import flash.events.EventDispatcher;
	
	import pragma.events.IEventDispatcher;

	public interface $IListener
	{
		function get dispatcher():IEventDispatcher;
		function get handler():Function;
		function get type():String;
		function get useCapture():Boolean;
		function get priority():int;
	}
}