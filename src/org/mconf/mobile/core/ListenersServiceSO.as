package org.mconf.mobile.core
{
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.net.SharedObject;
	
	import mx.utils.ObjectUtil;
	
	import org.mconf.mobile.model.ConnectionFailedEvent;
	import org.mconf.mobile.model.IConferenceParameters;
	import org.mconf.mobile.model.IUserSession;
	import org.mconf.mobile.model.User;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;

	public class ListenersServiceSO extends BaseServiceSO implements IListenersServiceSO
	{
		[Inject]
		public var userSession: IUserSession;
		
		private static const SO_NAME:String = "meetMeUsersSO";
		private var _muteStateSignal:ISignal = new Signal();
		
		public function ListenersServiceSO() {
			super(SO_NAME);
		}
		
		override public function connect(connection:NetConnection, uri:String, params:IConferenceParameters):void {
			super.connect(connection, uri, params);
			
			// Query the server if there are already listeners in the conference.
			getCurrentUsers();
			getRoomMuteState();
		}
		
		private function getCurrentUsers():void {
			var nc:NetConnection = userSession.mainConnection.connection;
			nc.call(
				"voice.getMeetMeUsers",// Remote function name
				new Responder(
					// participants - On successful result
					function(result:Object):void { 
						trace("Successfully queried listeners: " + result.count); 
						if (result.count > 0) {
							for(var p:Object in result.participants) {
								participantJoined(result.participants[p]);
							}
						}	
					},	
					// status - On error occurred
					function(status:Object):void { 
						trace("Error occurred");
						trace(ObjectUtil.toString(status));
						sendConnectionFailedEvent(ConnectionFailedEvent.UNKNOWN_REASON);
					}
				)//new Responder
			); //_netConnection.call
		}
		
		private function getRoomMuteState():void {
			var nc:NetConnection = userSession.mainConnection.connection;
			nc.call(
				"voice.isRoomMuted",// Remote function name
				new Responder(
					// participants - On successful result
					function(result:Object):void {
						_muteStateSignal.dispatch(result as Boolean);
					},	
					// status - On error occurred
					function(status:Object):void { 
						trace("Error occurred");
						trace(ObjectUtil.toString(status));
						sendConnectionFailedEvent(ConnectionFailedEvent.UNKNOWN_REASON);
					}
				)//new Responder
			); //_netConnection.call
		}

		private function participantJoined(joinedUser:Object):void {
			var userId:Number = joinedUser.participant;
			var cidName:String = joinedUser.name;
			var cidNum:String = joinedUser.name;
			var muted:Boolean = joinedUser.muted; 
			var talking:Boolean = joinedUser.talking;
			var locked:Boolean = joinedUser.locked;
			
			userJoin(userId, cidName, cidNum, muted, talking, locked);
		}

		public function get muteStateSignal():ISignal
		{
			return _muteStateSignal;
		}

		public function set muteStateSignal(value:ISignal):void
		{
			_muteStateSignal = value;
		}


		/**
		 * Callback from the server from many of the bellow nc.call methods
		 */
		
		public function userJoin(userId:Number, cidName:String, cidNum:String, muted:Boolean, talking:Boolean, locked:Boolean):void {
			trace("New listener joined ["
				+ "userId:" + userId + "," 
				+ "cidName:" + cidName + "," 
				+ "cidNum:" + cidNum + "," 
				+ "muted:" + muted + "," 
				+ "talking:" + talking + "," 
				+ "locked:" + locked + "]");
		}
		
		public function userMute(userID:Number, mute:Boolean):void {
			trace("userMuted() [" + userID + "," + mute + "]");
		}
		
		public function userLockedMute(userID:Number, locked:Boolean):void {
			trace("userLockedMute() [" + userID + "," + locked + "]");
		}

		public function userTalk(userID:Number, talk:Boolean):void {
			trace("userTalk() [" + userID + "," + talk + "]");
		}
		
		public function userLeft(userID:Number):void {
			trace("userTalk() [" + userID + "]");
		}
		
		public function ping(message:String):void {
			trace("ping() [" + message + "]");
		}		
	}
}