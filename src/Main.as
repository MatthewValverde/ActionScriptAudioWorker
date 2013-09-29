package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Matthew Valverde
	 */
	
	
	[SWF(backgroundColor=0xffffff,frameRate=30,width=515,height=330)]
	
	public class Main extends Sprite
	{
		[Embed(source="./../lib/AudioWorker.swf",mimeType="application/octet-stream")]
		private static var WorkerByteClass:Class;
	
		private var audioDataRecieved:ByteArray;
		private var audioWorker:Worker;
		private var mainToBackChannel:MessageChannel;
		private var backToMainChannel:MessageChannel;
		
		public function Main()
		{
			initWorker();
			
			var mySound:Sound = new Sound();
			mySound.addEventListener(SampleDataEvent.SAMPLE_DATA, sineWaveGenerator);
			mySound.play();
		}
		
		private function sineWaveGenerator(event:SampleDataEvent):void
		{
			var data:ByteArray = event.data;
			var bytes:ByteArray = new ByteArray();
			
			bytes.writeObject({'position': event.position, 'eventData': data})
			audioWorker.setSharedProperty('audioBytes', bytes);
			mainToBackChannel.send("BYTES");
			
			if (audioDataRecieved != null && audioDataRecieved.length != 0)
			{
				data.writeBytes(audioDataRecieved);
			}
			else
			{
				for (var j:int = 0; j < 8192; j++)
				{
					data.writeFloat(0);
					data.writeFloat(0);
				}
			}
		}
		
		private function initWorker():void
		{
			var workerByteClass:ByteArray = new WorkerByteClass();
			audioWorker = WorkerDomain.current.createWorker(workerByteClass);
			
			mainToBackChannel = Worker.current.createMessageChannel(audioWorker);
			backToMainChannel = audioWorker.createMessageChannel(Worker.current);
			
			audioWorker.setSharedProperty("backToMainChannel", backToMainChannel);
			audioWorker.setSharedProperty("mainToBackChannel", mainToBackChannel);
			
			backToMainChannel.addEventListener(Event.CHANNEL_MESSAGE, onBackToMain, false, 0, true);
			
			audioWorker.start();
		}
		
		private function onBackToMain(event:Event):void
		{
			if (backToMainChannel.messageAvailable)
			{
				var msg:* = backToMainChannel.receive();
				
				if (msg == "COMPLETE")
				{
					audioDataRecieved = audioWorker.getSharedProperty('audioDataComplete');					
				}
			}
		}
	}
}