//! A Lightclient test may involve hosting a server to send data to the LightClient. This trait can be asked to set simple scenarios where a mock LightServer sends data showing a note to a LightClient, the LightClient updates and responds by sending the note, and the Lightserver accepts the transaction and rebroadcasts it...
//! The initial two implementors are
//! lib-to-node, which links a lightserver to a zcashd in regtest mode. see `impl ConductChain for LibtoNode
//! darkside, a mode for the lightserver which mocks zcashd. search 'impl ConductChain for DarksideScenario

use crate::{get_base_address_macro, lightclient::from_inputs};
use zingolib::lightclient::LightClient;

#[allow(async_fn_in_trait)]
#[allow(opaque_hidden_inferred_bound)]
/// a trait (capability) for operating a server.
/// delegates client setup, because different mock servers require different client configuration
/// currently, the server conductor is limited to adding to the mock blockchain linearly (bump chain)
pub trait ConductChain {
    /// set up the test chain
    async fn setup() -> Self;
    /// builds a faucet (funded from mining)
    async fn create_faucet(&mut self) -> LightClient;
    /// builds an empty client
    async fn create_client(&mut self) -> LightClient;

    /// moves the chain tip forward, creating 1 new block
    /// and confirming transactions that were received by the server
    async fn bump_chain(&mut self);

    /// builds a client and funds it in orchard and syncs it
    async fn fund_client_orchard(&mut self, value: u64) -> LightClient {
        let faucet = self.create_faucet().await;
        let recipient = self.create_client().await;

        self.bump_chain().await;
        faucet.do_sync(false).await.unwrap();

        from_inputs::quick_send(
            &faucet,
            vec![(
                (get_base_address_macro!(recipient, "unified")).as_str(),
                value,
                None,
            )],
        )
        .await
        .unwrap();

        self.bump_chain().await;

        recipient.do_sync(false).await.unwrap();

        recipient
    }
}