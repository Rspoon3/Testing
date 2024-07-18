//
//  MusicPlayer.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/17/24.
//

import MediaPlayer

class MusicPlayer {
    var songTwo: MPMediaItem?
    let player = MPMusicPlayerController.applicationMusicPlayer
    
    func start() async {
        await MPMediaLibrary.requestAuthorization()

        let myPlaylistsQuery = MPMediaQuery.playlists()
        let playlists = myPlaylistsQuery.collections!.filter { $0.items.count > 2}
        let playlist = playlists.first!
        let songOne = playlist.items.first!
        songTwo = playlist.items[1]
        
        player.setQueue(with: playlist)
        play(songOne)
    }
    
    func newSong() {
        guard let songTwo else { return }
        play(songTwo)
    }
    
    private func play(_ song: MPMediaItem) {
        player.stop()
        player.nowPlayingItem = song
        player.prepareToPlay()
        player.play()
    }
}
