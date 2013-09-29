package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.net.registerClassAlias;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.ByteArray;
	import flash.media.Sound;
	
	/**
	 * ...
	 * @author Matthew Valverde
	 */
	
	public class AudioWorker extends Sprite
	{
		private var mainToBackChannel:MessageChannel;
		private var backToMainChannel:MessageChannel;
		
		public function AudioWorker()
		{
			super();
			
			var worker:Worker = Worker.current;
			
			mainToBackChannel = worker.getSharedProperty("mainToBackChannel");
			backToMainChannel = worker.getSharedProperty("backToMainChannel");
			
			mainToBackChannel.addEventListener(Event.CHANNEL_MESSAGE, onMainToBack);
		}
		
		private function onMainToBack(event:Event):void
		{
			if (mainToBackChannel.messageAvailable)
			{
				var msg:* = mainToBackChannel.receive();
				
				if (msg == "BYTES")
				{
					sample();
					
					backToMainChannel.send('COMPLETE');
				}
			}
		}
		
		private function sample():void
		{
			var worker:Worker = Worker.current;
			var bytes:ByteArray = worker.getSharedProperty('audioBytes');
			bytes.position = 0;
			var object:Object = bytes.readObject();
			var data:ByteArray = object.eventData as ByteArray;
			var pos:Number = object.position as Number;
			
			for (var c:int = 0; c < 8192; c++)
			{
				data.writeFloat(Math.sin((Number(c + pos) / Math.PI / 8)) * 0.25);
				data.writeFloat(Math.sin((Number(c + pos) / Math.PI / 8)) * 0.25);
			}
			
			worker.setSharedProperty('audioDataComplete', data);
		}
	
	}
}