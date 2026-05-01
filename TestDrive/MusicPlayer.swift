//
//  MusicPlayer.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/17/24.
//

import MediaPlayer

class MusicPlayer {
    let player = MPMusicPlayerController.applicationMusicPlayer
    var playlist: MPMediaItemCollection?
    
    func start() async {
        await MPMediaLibrary.requestAuthorization()
        
        let myPlaylistsQuery = MPMediaQuery.playlists()
        
        playlist = myPlaylistsQuery.collections?.filter { $0.items.count > 2 }.first
        
        guard let playlist, let first = playlist.items.first else { return }
        
        for i in 0..<5 {
            print(playlist.items[i].title)
        }
        
        player.setQueue(with: playlist)
        play(first)
    }
    
    func newSong() {
        guard let playlist, let last = playlist.items.last else { return }
        player.setQueue(with: playlist)
        play(last)
    }
    
    private func play(_ song: MPMediaItem) {
        player.nowPlayingItem = song
        player.play()
    }
}
